import Foundation

class RequestManager {
	var pending_sends: [String: SendMessageRequest] = [String: SendMessageRequest]()
	let settings = Settings.shared()
	let chat_delegate = ChatDelegate.shared()
	static let sharedManager = RequestManager()

	func handleString(_ str: String) {
		Const.log("Decoding string \(str)")

		guard let object = Const.jsonToDict(string: str) else {
			return
		}

		let request = SocketMessage(object, incoming: true)

		handleRequest(request)
	}

	func handleRequest(_ msg: SocketMessage) {
		DispatchQueue.main.async {
			switch msg.command {
				case .GetChats, .GetMessages, .GetName:
					self.handleJsonRequest(msg)
				case .GetAttachment, .GetIcon:
					self.handleDataRequest(msg)
				case .SendTapback, .DeleteChat, .DeleteText:
					self.handleSendRequest(msg)
				case .SendMessage:
					self.handleSendMessage(msg)
				case .AttachmentData:
					self.handleAttachmentData(msg)
				case .SendTyping:
					self.handleTyping(msg)
				default:
					Const.log("Enum variant \(msg.command) should never be sent to the host")
			}
		}
	}

	func handleJsonRequest(_ msg: SocketMessage) {
		Const.log("Msg is a parseAndReturn request")

		var str_dict = (msg.data as? [String:Any] ?? [String:Any]()).mapValues({ String(describing: $0) })

		if msg.command == .GetChats && str_dict[Const.api_chat_req] == nil {
			str_dict[Const.api_chat_req] = ""
		}

		Const.log("Send params \(str_dict) to parseAndReturn")

		let ret_data = ServerDelegate.parseAndReturn(params: str_dict, verify_auth: false)
		if ret_data.0 == 200 {
			Const.log("ret_data is good. Sending.")
			self.sendRequestResponse(msg, data: ret_data.1)
		} else {
			Const.log("ret_data is bad: \(ret_data.0), \(ret_data.1)")
		}
	}

	func handleSendMessage(_ msg: SocketMessage) {
		let dict = msg.data as? [String:Any] ?? [String:Any]()
		let msg_req = SendMessageRequest(dict)
		Const.log("Appending sendMessageRequest \(msg_req)")
		if let id = msg.id {

			if (dict["attachments"] as? [[String:Any]] ?? [[String:Any]]()).count > 0 {
				pending_sends[id] = msg_req
			} else {
				_ = ServerDelegate.sendText(params: dict, new_files: [String]())
			}
		}
	}

	func handleDataRequest(_ msg: SocketMessage) {
		let ret_data: Data = {
			if let data = msg.data as? [String:String] {
				switch msg.command {
					case APICommand.GetAttachment:
						let data_arr = self.chat_delegate.getAttachmentDataFromPath(path: data["path"] ?? "")
						return data_arr[0] as? Data ?? Data()
					case APICommand.GetIcon:
						return self.chat_delegate.returnImageData(chat_id: data["chat_id"] ?? "")
					default: break
				}
			}
			return Data()
		}()

		Const.log("Got data for data request: \(ret_data)")

		let encoded = ret_data.base64EncodedString()
		let chunk_size = 51200
		let string_len = encoded.count;
		var idx = 0
		var chunks = [String]()

		while idx < string_len {
			let chunk_start_idx = encoded.index(encoded.startIndex, offsetBy: idx)
			let chunk_end_idx = encoded.index(chunk_start_idx, offsetBy: min(chunk_size, string_len))
			let chunk = encoded[chunk_start_idx..<chunk_end_idx]

			chunks.append(String(chunk))
			idx += chunk_size
		}

		Const.log("Total chunks length: \(chunks.count)")

		for chunk in chunks {
			Const.log("Sending chunk...")

			let json_dict: [String:Any] = [
				"data": chunk,
				"total": chunks.count
			]

			self.sendRequestResponse(msg, data: json_dict)
		}
	}

	func handleSendRequest(_ msg: SocketMessage) {
		Const.log("Handling send request \(msg)")
		if let dict = msg.data as? [String:Any] {
			let str_dict = dict.mapValues({ String(describing: $0) })
			_ = ServerDelegate.sendGetRequest(params: str_dict)
		}
	}

	func handleAttachmentData(_ msg: SocketMessage) {
		guard let dict = msg.data as? [String:Any] else { return }

		let att_data = AttachmentData(dict)
		guard let send_req = pending_sends[att_data.message_id] else {
			Const.log("Couldn't get send_req for id \(att_data.message_id)")
			return
		}

		var finished = true

		for att in send_req.attachments {
			if att.id == att_data.attachment_id {
				Const.log("Appending data for attachment_id \(att.id)")
				att.data.append(att_data.data)
			}

			if finished {
				if att.received != att.size {
					Const.log("Have not received all data for att \(att). Received: \(att.received), size: \(att.size)")
					finished = false
				}
			}
		}

		if finished {
			Const.log("Have finished receiving data for message. Sending...")
			let fm = FileManager.default
			let doc_dir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]

			let file_dirs = send_req.attachments.map{ att -> String in
				let full_data = Data(base64Encoded: att.data.joined())
				let file_dir = "\(doc_dir)/\(att.filename)"

				fm.createFile(atPath: file_dir, contents: full_data, attributes:nil)

				Const.log("Placed data in file at \(file_dir)")

				return file_dir
			}

			let params = [
				"text": send_req.text,
				"chat": send_req.chat,
				"subject": send_req.subject,
				"photos": send_req.photos
			]

			Const.log("Sending message...")

			_ = ServerDelegate.sendText(params: params, new_files: file_dirs)

			pending_sends.removeValue(forKey: send_req.id)
		}
	}

	func handleTyping(_ msg: SocketMessage) {
		if let dict = msg.data as? [String:Any] {
			let typing = dict["active"] as? Bool ?? false
			let chat = dict["chat"] as? String ?? ""
			ServerDelegate.sender.sendTyping(typing, forChat: chat)
		}
	}

	func sendRequestResponse(_ msg: SocketMessage, data: Any) {
		let response = SocketMessage(msg.id, command: msg.command, data: data, incoming: false)
		StarscreamDelegate.sharedDelegate.sendData(data: response.json())
	}
}

let str_to_command: [String:APICommand] = [
	"get-chats": .GetChats,
	"get-messages": .GetMessages,
	"get-name": .GetName,
	"get-attachment": .GetAttachment,
	"get-icon": .GetIcon,
	"send-message": .SendMessage,
	"send-tapback": .SendTapback,
	"delete-chat": .DeleteChat,
	"delete-text": .DeleteText,
	"send-typing": .SendTyping,
	"typing": .Typing,
	"new-message": .NewMessage
]

class SocketRequest {
	init(_ dict: [String: Any]) {
		id = dict["id"] as? String ?? ""
		command = str_to_command[dict["command"] as? String ?? ""]
		params = dict["params"] as? [String:Any] ?? [String:Any]()
	}

	let id: String
	let command: APICommand?
	let params: [String: Any]
}

enum APICommand {
	case Indecipherable
	case GetChats
	case GetMessages
	case GetName
	case GetAttachment
	case GetIcon
	case SendMessage
	case AttachmentData
	case SendTapback
	case DeleteChat
	case DeleteText
	case SendTyping
	case Typing
	case NewMessage
}

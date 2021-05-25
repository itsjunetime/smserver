class SendMessageRequest {
	let id: String
	let command: APICommand = .SendMessage
	let chat: String
	let text: String
	let subject: String
	let photos: String
	let attachments: [Attachment]

	init(_ json: [String:Any]) {
		attachments = {
			if let atts = json["attachments"] as? [[String: Any]] {
				return atts.map{Attachment($0)}
			}
			return [Attachment]()
		}()

		chat = json["chat"] as? String ?? ""
		id = json["id"] as? String ?? ""
		text = json["text"] as? String ?? ""
		photos = json["photos"] as? String ?? ""
		subject = json["subject"] as? String ?? ""
	}
}

class Attachment {
	var id: String
	var size: Int
	var received: Int = 0
	var filename: String
	var data: [String] = [String]()

	init(_ json: [String: Any]) {
		id = json["id"] as? String ?? ""
		size = json["size"] as? Int ?? 0
		filename = json["filename"] as? String ?? ""
	}
}

class AttachmentData {
	var message_id: String
	var attachment_id: String
	var index: Int
	var data: String

	init(_ json: [String:Any]) {
		message_id = json["message_id"] as? String ?? ""
		attachment_id = json["attachment_id"] as? String ?? ""
		index = json["index"] as? Int ?? 0
		data = json["data"] as? String ?? ""
	}
}

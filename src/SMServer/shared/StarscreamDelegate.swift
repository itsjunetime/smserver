import Foundation

import Starscream

class StarscreamDelegate : NSObject, WebSocketDelegate {
	let settings = Settings.shared()
	var socket: WebSocket? = nil
	var socket_state: SocketState = SocketState.Disconnected
	var request_manager = RequestManager.sharedManager
	static let sharedDelegate = StarscreamDelegate()

	func registerAndConnect() -> Bool {
		let test_id = getID()

		guard let id = test_id else {
			return false
		}

		Const.log("Got id: '\(id)'")

		settings.remote_id = id
		let url_encoded = settings.password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? settings.password

		let conn_str = URL(string: "http\(settings.remote_secure ? "s" : "")://\(settings.remote_addr)/connect?id=\(id)&key=\(url_encoded)&sock_type=host")!
		var req = URLRequest(url: conn_str)
		req.timeoutInterval = 5

		let pinner = FoundationSecurity(allowSelfSigned: true)

		socket = WebSocket(request: req, certPinner: pinner)
		socket?.respondToPingWithPong = true
		socket?.delegate = self

		socket?.connect()

		socket_state = SocketState.Connecting

		return true
	}

	func getID() -> String? {
		let url_encoded = settings.password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? settings.password

		let url = URL(string: "http\(settings.remote_secure ? "s" : "")://\(settings.remote_addr)/register?key=\(url_encoded)&host_key=\(url_encoded)&reg_type=hostclient")!
		var ret_str: String? = nil

		var request = URLRequest(url: url)
		request.httpMethod = "GET"

		let group = DispatchGroup()
		group.enter()

		let urlSession: URLSession = {
			if settings.remote_bypass_cert {
				return URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
			} else {
				return URLSession(configuration: URLSessionConfiguration.default)
			}
		}()

		let task = urlSession.dataTask(with: request) {(data, response, err) in
			if let data = data {
				ret_str = String(data: data, encoding: .utf8)
			}
			group.leave()
		}

		task.resume()

		group.wait()
		return ret_str
	}

	func didReceive(event: WebSocketEvent, client: WebSocket) {
		switch event {
			case .connected(_):
				socket_state = SocketState.Connected
			case .disconnected(_, _):
				socket_state = SocketState.Disconnected
			case .text(let string):
				request_manager.handleString(string)
			case .cancelled:
				socket_state = SocketState.Disconnected
			case .error(_):
				socket_state = SocketState.Disconnected
			default:
				break
		}
	}

	func sendTyping(_ chat: String, typing: Bool) {
		let msg = SocketMessage.typing(chat, active: typing)
		self.sendData(data: msg.json())
	}

	func sendNewMessage(_ msg: [String:Any]) {
		let new_msg = SocketMessage.newMessage(msg)
		self.sendData(data: new_msg.json())
	}

	func sendData(data: Any) {
		let json = Const.encodeToJson(object: data, title: nil)
		socket?.write(string: json)
	}
}

extension StarscreamDelegate : URLSessionDelegate {
	func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
		completionHandler(.useCredential, urlCredential)
	}
}

enum SocketState {
	case Connected, Connecting, Disconnected
}

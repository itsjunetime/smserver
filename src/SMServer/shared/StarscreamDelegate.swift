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

		Const.log("Got remote id: '\(id)'")

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

	func disconnect() {
		socket?.disconnect()
	}

	func getID() -> String? {
		let url_encoded = settings.password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? settings.password

		let url = URL(string: "http\(settings.remote_secure ? "s" : "")://\(settings.remote_addr)/register?key=\(url_encoded)&host_key=\(url_encoded)&reg_type=hostclient")!
		var ret_str: String? = nil

		var request = URLRequest(url: url)
		request.httpMethod = "GET"

		let group = DispatchGroup()
		group.enter()

		let config = URLSessionConfiguration.default
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 10

		let urlSession: URLSession = {
			if settings.remote_bypass_cert {
				return URLSession(configuration: config, delegate: self, delegateQueue: nil)
			} else {
				return URLSession(configuration: config)
			}
		}()

		let task = urlSession.dataTask(with: request) {(data, response, err) in
			if let data = data {
				ret_str = String(data: data, encoding: .utf8)
			}
			group.leave()
		}

		Const.log("Creating session with url \(url)")

		task.resume()

		group.wait()
		return ret_str
	}

	func didReceive(event: WebSocketEvent, client: WebSocket) {
		Const.log("Received event: \(event)")
		switch event {
			case .connected(_):
				socket_state = SocketState.Connected
			case .disconnected(_, _):
				socket_state = SocketState.Disconnected
			case .text(let string):
				// we can't really just send a battery message when they first connect since the .connected(_) event
				// is only called when it first connects to the remote server, so I guess just send it whenever they request anything?
				// Ideally we'd have a way of detecting the first request from a certain host, and only sending it on that, but nothing
				// like that yet.
				DispatchQueue.main.async {
					self.sendBattery()
				}
				request_manager.handleString(string)
			case .cancelled:
				socket_state = SocketState.Disconnected
			case .error(_):
				socket_state = SocketState.Disconnected
			default:
				break
		}
	}
	
	func sendBattery() {
		let perc = Const.getBatteryLevel()
		let state = Const.getBatteryState()
		let charging = state == .charging || state == .full
		
		let msg = SocketMessage.battery(perc, charging: charging)
		Const.log("Sending battery msg: \(msg)")
		self.sendData(data: msg.json())
	}

	func sendTyping(_ chat: String, typing: Bool) {
		let msg = SocketMessage.typing(chat, active: typing)
		Const.log("Sending typing msg: \(msg)")
		self.sendData(data: msg.json())
	}

	func sendNewMessage(_ msg: [String:Any]) {
		let new_msg = SocketMessage.newMessage(msg)
		Const.log("Sending new msg: \(msg)")
		self.sendData(data: new_msg.json())
	}

	func sendData(data: Any) {
		let json = Const.encodeToJson(object: data, title: nil)
		Const.log("Sending data: \(json)")
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

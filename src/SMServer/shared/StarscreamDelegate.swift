import Foundation

import Starscream

class StarscreamDelegate : NSObject, WebSocketDelegate {
	let settings = Settings.shared()
	var socket: WebSocket? = nil
	var socket_state: SocketState = SocketState.Disconnected(false)
	var request_manager = RequestManager.sharedManager
	static let sharedDelegate = StarscreamDelegate()

	func registerAndConnect() -> Bool {
		guard let id = (settings.remote_id ?? getID()) else {
			return false
		}

		Const.log("Got remote id: '\(id)'")

		settings.remote_id = id
		let url_encoded = settings.password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? settings.password

		guard let conn_str = URL(string: "http\(settings.remote_secure ? "s" : "")://\(settings.remote_addr)/connect?id=\(id)&key=\(url_encoded)&sock_type=host") else {
			return false
		}
		var req = URLRequest(url: conn_str)
		req.timeoutInterval = 5

		let pinner = FoundationSecurity(allowSelfSigned: true)

		socket = WebSocket(request: req, certPinner: pinner)
		socket?.respondToPingWithPong = true
		socket?.delegate = self

		socket?.connect()

		setSocketState(new_state: .Connecting)

		return true
	}

	func disconnect() {
		// need to set disconnected state before actually disconnecting
		// or else it'll think we accidentally disconnected and will try to reconnect
		setSocketState(new_state: .Disconnected(false))

		socket?.disconnect()
		_ = self.deregister() // eh we'll handle the result later

		settings.remote_id = nil
	}

	func getID() -> String? {
		let url_encoded = settings.password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? settings.password

		let id_req = settings.remote_id != nil ? "&id_req=\(settings.remote_id ?? "")" : ""

		guard let url = URL(string: "http\(settings.remote_secure ? "s" : "")://\(settings.remote_addr)/register?key=\(url_encoded)&host_key=\(url_encoded)&reg_type=hostclient\(id_req)") else {
			Const.log("Error: You have characters in your remote address which should not be in URLs. Please remove them")

			return nil
		}
		var ret_str: String? = nil

		let group = DispatchGroup()
		group.enter()

		Const.log("Creating session with url \(url)")

		self.getURLSessionAndRequest(url, completion: {(data, _, _) in
			if let data = data {
				ret_str = String(data: data, encoding: .utf8)
			}
			group.leave()
		})

		group.wait()
		return ret_str
	}

	func deregister() -> Bool {
		var succeeded = true

		guard let id = settings.remote_id, id.count > 0 else {
			// still return true 'cause we didn't even have to deregister
			return true
		}

		let url_encoded = settings.password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? settings.password
		guard let url = URL(string: "http\(settings.remote_secure ? "s" : "")://\(settings.remote_addr)/remove?id=\(id)&key=\(url_encoded)&host_key=\(url_encoded)") else {
			Const.log("Error: You have characters in your remote address which should not be in URLs. Please remove them")

			return false
		}

		let group = DispatchGroup()
		group.enter()

		Const.log("Removing session with id \(settings.remote_id ?? "unknown")")

		self.getURLSessionAndRequest(url, completion: {(data, _, error) in
			if let err = error {
				Const.log("Could not remove session: \(err)")
				succeeded = false
			}

			group.leave()
		})

		group.wait()
		return succeeded
	}

	func getURLSessionAndRequest(_ url: URL, completion: @escaping (_: Data?, _: URLResponse?, _: Error?) -> Void) {
		var request = URLRequest(url: url)
		request.httpMethod = "GET"

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

		let task = urlSession.dataTask(with: request, completionHandler: completion)
		task.resume()
	}

	func didReceive(event: WebSocketEvent, client: WebSocket) {
		Const.log("Received event: \(event)")
		switch event {
			case .connected(_):
				setSocketState(new_state: .Connected)
			case .disconnected(_, _), .cancelled, .error(_), .reconnectSuggested(_):
				socketDisconnected()
			case .text(let string):
				// we can't really just send a battery message when they first connect since the .connected(_) event
				// is only called when it first connects to the remote server, so I guess just send it whenever they request anything?
				// Ideally we'd have a way of detecting the first request from a certain host, and only sending it on that, but nothing
				// like that yet.
				DispatchQueue.main.async {
					self.sendBattery()
				}
				request_manager.handleString(string)
			default:
				break
		}
	}

	func socketDisconnected() {
		switch socket_state {
			case .Disconnected(_):
				break
			default:
				setSocketState(new_state: .Disconnected(true))
		}
	}

	func setSocketState(new_state: SocketState) {
		socket_state = new_state
		NotificationCenter.default.post(name: Notification.Name(Const.ss_changed_notification), object: new_state)
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
	case Connected, Connecting, Disconnected(Bool), Reconnecting, FailedConnect
}

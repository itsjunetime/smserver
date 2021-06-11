import Foundation
import Telegraph

class SocketDelegate : ServerWebSocketDelegate {
	let settings = Settings.shared()
	var server: Server? = nil
	var watcher: IPCTextWatcher? = nil
	var verify_auth: (String)->(Bool) = { _ in return false } /// nil init
	let prefix: String = "SMServer_app: "

	func startServer(port: Int) {
		let cert = Certificate(derURL: (Bundle.main.url(forResource: "cert", withExtension: "der")!))
		let identity = CertificateIdentity(p12URL: Bundle.main.url(forResource: "identity", withExtension: "pfx")!, passphrase: settings.cert_pass)

		if settings.is_secure {
			self.server = Server(identity: identity!, caCertificates: [cert!])
		} else {
			self.server = Server()
		}

		server?.webSocketDelegate = self

		do {
			try server?.start(port: port)
			Const.log("Started websocket successfully.")
		} catch {
			Const.log("The websocket failed to start. This will prevent you from receiving new messages.", warning: true)
		}
	}

	func stopServer() {
		server?.stop()

		Const.log("Socket stopped")

		if let sock = server {
			for s in sock.webSockets {
				s.close(immediately: false)
			}
		}
	}

	func sendTyping(_ chat: String, typing: Bool = true) {
		let json: [String:Any] = [
			"chat": chat,
			"active": typing
		]

		let msg = SocketMessage(nil, command: .Typing, data: json, incoming: false)
		let json_str = Const.encodeToJson(object: msg.json())

		if let sock = server {
			for i in sock.webSockets {
				i.send(text: json_str)
			}
		}
	}

	@objc func sendNewBatteryFromNotification(notification: NSNotification) {
		sendNewBattery()
	}

	func sendNewBattery() {
		let percent = Const.getBatteryLevel()
		let charging_state = Const.getBatteryState()

		let json: [String: Any] = [
			"charging": charging_state == .charging || charging_state == .full,
			"percentage": percent
		]

		let msg = SocketMessage(nil, command: .BatteryStatus, data: json, incoming: false, last: true)

		let json_str = Const.encodeToJson(object: msg.json(), title: nil)

		if let sock = server {
			for i in sock.webSockets {
				i.send(text: json_str)
			}
		}
	}

	func sendNewText(info: [String:Any]) {
		let msg = SocketMessage(nil, command: .NewMessage, data: info, incoming: false)
		let json = Const.encodeToJson(object: msg.json())

		/// If we received a new text
		if let sock = server {
			for i in sock.webSockets {
				i.send(text: json)
			}
		}
	}

	func sendTextRead(_ guid: String, date: String) {
		let json = [
			"guid": guid,
			"date": date
		]

		let msg = SocketMessage(nil, command: .ReadMessage, data: json, incoming: false)
		let json_str = Const.encodeToJson(object: msg.json())

		if let sock = server {
			for i in sock.webSockets {
				i.send(text: json_str)
			}
		}
	}

	func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
		// A web socket connected, you can extract additional information from the handshake request
		let ip = webSocket.remoteEndpoint?.host ?? ""

		Const.log("\(ip) is trying to connect...")

		if !verify_auth(ip) {
			Const.log("\(ip) is not verified. Disconnecting.")
			webSocket.close(immediately: true)
			return
		}

		Const.log("\(ip) was allowed to connect")

		self.sendNewBattery()
	}

	func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
		// One of our web sockets disconnected
		Const.log("Socket at \(webSocket.remoteEndpoint?.host ?? "") disconnected")
	}

	func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
		// One of our web sockets sent us a message
		guard message.payload.data != nil else {
			return
		}
		Const.log("Received message: \(message)")
		switch message.payload {
			case .text(let msg):
				let context = msg.split(separator: ":")[0]

				if (context == "typing" || context == "idle") && settings.send_typing {
					let content = msg.split(separator: ":")[1]
					ServerDelegate.sender.sendTyping(String(context) == "typing", forChat: String(content))
				}
			default:
				if message.opcode == WebSocketOpcode.binaryFrame || message.opcode == WebSocketOpcode.textFrame {
					Const.log("WARNING: can't handle message: \(message)", warning: true)
				}
		}
	}
}

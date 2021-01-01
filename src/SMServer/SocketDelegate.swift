import Foundation
import Telegraph

class SocketDelegate : ServerWebSocketDelegate {

	static let cert = Certificate(derURL: (Bundle.main.url(forResource: "cert", withExtension: "der")!))
	/// This passphrase is found in a hidden file that doesn't exist in the git repo. This is so that nobody can extract the private key from the pfx file
	static let identity = CertificateIdentity(p12URL: Bundle.main.url(forResource: "identity", withExtension: "pfx")!, passphrase: PKCS12Identity.pass)
	var server: Server? = nil
	var watcher: IPCTextWatcher? = nil
	var authenticated_addresses = [String]()
	var verify_auth: (String)->(Bool) = { _ in return false } /// nil init
	let prefix: String = "SMServer_app: "

	var debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	var send_typing = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true

	func refreshVars() {
		self.debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
		self.send_typing = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true
	}

	func startServer(port: Int) {
		if UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true {
			self.server = Server(identity: SocketDelegate.identity!, caCertificates: [SocketDelegate.cert!])
		} else {
			self.server = Server()
		}

		server?.webSocketDelegate = self

		do {
			try server?.start(port: port)
			Const.log("Started websocket successfully.", debug: self.debug)

		} catch {
			Const.log("WARNING: The websocket failed to start. This will prevent you from receiving new messages.", debug: self.debug, warning: true)
		}
	}

	func stopServer() {
		server?.stop()

		Const.log("Socket stopped", debug: self.debug)
	}

	func sendTyping(_ chat: String, typing: Bool = true) {
		if server != nil {
			let send_str = "\(typing ? "typing" : "idle"):\(chat)"
			for i in server!.webSockets {
				i.send(text: send_str)
			}
		}
	}

	@objc func sendNewBatteryFromNotification(notification: NSNotification) {
		sendNewBattery()
	}

	func sendNewBattery() {
		let percent = UIDevice.current.batteryLevel * 100
		let charging_state = UIDevice.current.batteryState
		var state_string = "charging"
		if charging_state == .unplugged || charging_state == .unknown {
			state_string = "unplugged"
		}

		if server != nil {
			for i in server!.webSockets {
				i.send(text: "battery:\(String(percent))")
				i.send(text: "battery:\(state_string)")
			}
		}
	}

	func sendNewText(info: String) {
		/// If we received a new text
		if server != nil {
			for i in server!.webSockets {
				i.send(text: "text:" + info)
			}
		}
	}

	func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
		// A web socket connected, you can extract additional information from the handshake request
		let ip = webSocket.remoteEndpoint?.host ?? ""

		Const.log("\(ip) is trying to connect...", debug: self.debug)

		if !verify_auth(ip) {
			Const.log("\(ip) is not verified. Disconnecting.", debug: self.debug)
			webSocket.close(immediately: true)
		}

		Const.log("\(ip) was allowed to connect", debug: self.debug)

		UIDevice.current.isBatteryMonitoringEnabled = true

		let battery_level = UIDevice.current.batteryLevel * 100
		let charging_state = UIDevice.current.batteryState
		var state_string = "charging"
		if charging_state == .unplugged || charging_state == .unknown {
			state_string = "unplugged"
		}

		webSocket.send(text: "battery:\(String(battery_level))")
		webSocket.send(text: "battery:\(state_string)")

		NotificationCenter.default.addObserver(self, selector: #selector(self.sendNewBatteryFromNotification(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.sendNewBatteryFromNotification(notification:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
	}

	func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
		// One of our web sockets disconnected
		Const.log("Socket at \(webSocket.remoteEndpoint?.host ?? "") disconnected", debug: self.debug)
	}

	func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
		// One of our web sockets sent us a message
		guard message.payload.data != nil else {
			return
		}
		Const.log("Received message: \(message)", debug: self.debug)
		switch message.payload {
			case .text(let msg):
				let context = msg.split(separator: ":")[0]

				if (context == "typing" || context == "idle") && self.send_typing {
					let content = msg.split(separator: ":")[1]
					ServerDelegate.sender.sendTyping(String(context) == "typing", forChat: String(content))
				}
			default:
				if message.opcode == WebSocketOpcode.binaryFrame || message.opcode == WebSocketOpcode.textFrame {
					Const.log("WARNING: can't handle message: \(message)", debug: self.debug, warning: true)
				}
		}
	}
}

import Foundation
import Telegraph

class SocketDelegate : ServerWebSocketDelegate {
	let settings = Settings.shared()
	var server: Server? = nil
	var watcher: IPCTextWatcher? = nil
	var verify_auth: (String)->(Bool) = { _ in return false } /// nil init
	let prefix: String = "SMServer_app: "

	var debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false

	init() {
		self.debug = settings.debug
	}

	func refreshVars() {
		self.debug = settings.debug
	}

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
			Const.log("Started websocket successfully.", debug: self.debug)
		} catch {
			Const.log("The websocket failed to start. This will prevent you from receiving new messages.", debug: self.debug, warning: true)
		}
	}

	func stopServer() {
		server?.stop()

		Const.log("Socket stopped", debug: self.debug)

		if let sock = server {
			for s in sock.webSockets {
				s.close(immediately: false)
			}
		}
	}

	func sendTyping(_ chat: String, typing: Bool = true) {
		if let sock = server {
			let send_str = "\(typing ? "typing" : "idle"):\(chat)"
			for i in sock.webSockets {
				i.send(text: send_str)
			}
		}
	}

	@objc func sendNewBatteryFromNotification(notification: NSNotification) {
		sendNewBattery()
	}

	func sendNewBattery() {
		let percent = Const.getBatteryLevel()
		let charging_state = Const.getBatteryState()

		var state_string = "charging"
		if charging_state == .unplugged || charging_state == .unknown {
			state_string = "unplugged"
		}

		if let sock = server {
			for i in sock.webSockets {
				i.send(text: "battery:\(String(percent))")
				i.send(text: "battery:\(state_string)")
			}
		}
	}

	func sendNewText(info: String) {
		/// If we received a new text
		if let sock = server {
			for i in sock.webSockets {
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

		#if os(iOS)
		UIDevice.current.isBatteryMonitoringEnabled = true
		#endif

		let battery_level = Const.getBatteryLevel()
		let charging_state = Const.getBatteryState()
		var state_string = "charging"
		if charging_state == .unplugged || charging_state == .unknown {
			state_string = "unplugged"
		}

		webSocket.send(text: "battery:\(String(battery_level))")
		webSocket.send(text: "battery:\(state_string)")

		#if os(iOS)
		NotificationCenter.default.addObserver(self, selector: #selector(self.sendNewBatteryFromNotification(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.sendNewBatteryFromNotification(notification:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
		#elseif os(macOS)
		DispatchQueue.main.async {
			while true { /// yes. This is terrible.
				sleep(10)
				self.sendNewBattery()
			}
		}
		#endif
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

				if (context == "typing" || context == "idle") && settings.send_typing {
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

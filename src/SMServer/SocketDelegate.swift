import Foundation
import Telegraph
import os

class SocketDelegate : ServerWebSocketDelegate {
	
	static let cert = Certificate(derURL: (Bundle.main.url(forResource: "cert", withExtension: "der")!))
	static let identity = CertificateIdentity(p12URL: Bundle.main.url(forResource: "identity", withExtension: "pfx")!, passphrase: "smserver")
	var server: Server? = nil
	var watcher: IPCTextWatcher? = nil
	var authenticated_addresses = [String]()
	var verify_auth: (String)->(Bool) = { _ in return false } /// nil init
	let prefix: String = "SMServer_app: "
	
	var debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	var send_typing = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true
	
	func log(_ s: String, warning: Bool = false) {
		if self.debug || warning {
			os_log("%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, self.prefix, s)
		}
	}
	
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
			self.log("Started websocket successfully.")
			
		} catch {
			self.log("WARNING: The websocket failed to start. This will prevent you from receiving new messages.", warning: true)
		}
		
		// add observer for name "__kIMChatMessageReceivedNotification"
	}
	
	func stopServer() {
		server?.stop()
		
		self.log("Socket stopped")
	}
	
	func sendTyping(chat: String) {
		if server != nil {
			for i in server!.webSockets {
				i.send(text: "typing:" + chat)
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
		
		self.log("\(ip) is trying to connect...")
		
		if !verify_auth(ip) {
			self.log("\(ip) is not verified. Disconnecting.")
			webSocket.close(immediately: true)
		}
		
		self.log("\(ip) was allowed to connect")
			
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
		self.log("Socket disconnected")
	}
	
	func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
		// One of our web sockets sent us a message
		guard message.payload.data != nil else {
			return
		}
		self.log("Received message: \(message)")
		switch message.payload {
			case .text(let msg):
				let context = msg.split(separator: ":")[0]
				
				if (context == "typing" || context == "idle") && self.send_typing {
					let content = msg.split(separator: ":")[1]
					ContentView.sender.sendTyping(String(context) == "typing", forChat: String(content))
				}
			default:
				if message.opcode == WebSocketOpcode.binaryFrame || message.opcode == WebSocketOpcode.textFrame {
					log("WARNING: can't handle message: \(message)", warning: true)
				}
		}
	}
}

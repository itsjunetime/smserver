import Foundation
import Telegraph
import os
import NetworkExtension

class SocketDelegate : ServerWebSocketDelegate {
	
    static let cert = Certificate(derURL: (Bundle.main.url(forResource: "cert", withExtension: "der")!))
    static let identity = CertificateIdentity(p12URL: Bundle.main.url(forResource: "identity", withExtension: "pfx")!, passphrase: "smserver")
    let server = Server(identity: SocketDelegate.identity!, caCertificates: [SocketDelegate.cert!])
	var watcher: IPCTextWatcher? = nil
	var authenticated_addresses = [String]()
	var verify_auth: (String)->(Bool) = { _ in return false } /// nil init
	let prefix = "SMServer_app: "
	
	var sendTypingNotifs = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true
	
	func log(_ s: String) {
		os_log("%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, self.prefix, s)
	}
	
	func startServer(port: Int) {
		server.webSocketDelegate = self
		
		try! server.start(port: port)
	}
	
	func stopServer() {
		server.stop()
	}
	
	func sendTyping(chat: String) {
		for i in server.webSockets {
			i.send(text: "typing:" + chat)
		}
	}
	
	func sendNewBattery(notification: NSNotification) {
		let percent = UIDevice.current.batteryLevel * 100
		
		for i in server.webSockets {
			i.send(text: "battery:" + String(percent))
		}
	}
	
	func sendNewText(info: String) {
        /// If we received a new text
		for i in server.webSockets {
			i.send(text: "text:" + info)
		}
	}
	
	func sendNewWifi() {
		/// Don't know what data type to send
	}
	
	func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
		// A web socket connected, you can extract additional information from the handshake request
		
		if !verify_auth(webSocket.remoteEndpoint?.host ?? "") {
			webSocket.close(immediately: true)
		}
		
		let battery_level = UIDevice.current.batteryLevel * 100
		
		webSocket.send(text: "battery:\(String(battery_level))")

		/// Backgrounding doesn't work with the next line uncommented
		//NotificationCenter.default.addObserver(self, selector: Selector(("sendNewBattery:")), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
	}

	func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
		// One of our web sockets disconnected
	}

	func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
		// One of our web sockets sent us a message
	}

	func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {
		// We sent one of our web sockets a message (often you won't need to implement this one)
	}
}


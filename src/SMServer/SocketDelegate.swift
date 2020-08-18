import Foundation
import Telegraph
import os
import NetworkExtension

class SocketDelegate : ServerWebSocketDelegate {
	
    static let cert = Certificate(derURL: (Bundle.main.url(forResource: "cert", withExtension: "der")!))
    static let identity = CertificateIdentity(p12URL: Bundle.main.url(forResource: "identity", withExtension: "pfx")!, passphrase: "smserver")
    //let server = UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true ? Server(identity: SocketDelegate.identity!, caCertificates: [SocketDelegate.cert!]) : Server()
    var server: Server? = nil
	var watcher: IPCTextWatcher? = nil
	var authenticated_addresses = [String]()
	var verify_auth: (String)->(Bool) = { _ in return false } /// nil init
	let prefix = "SMServer_app: "
    
    var debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	var sendTypingNotifs = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true
	
	func log(_ s: String) {
		os_log("%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, self.prefix, s)
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
            if self.debug {
                self.log("Started websocket successfully.")
            }
        } catch {
            self.log("WARNING: The websocket failed to start. This will prevent you from receiving new messages.")
        }
	}
	
	func stopServer() {
        server?.stop()
	}
	
	func sendTyping(chat: String) {
        if server != nil {
            for i in server!.webSockets {
                i.send(text: "typing:" + chat)
            }
        }
	}
	
	func sendNewBattery() {
		let percent = UIDevice.current.batteryLevel * 100
		
        if server != nil {
            for i in server!.webSockets {
                i.send(text: "battery:" + String(percent))
            }
        }
	}
	
	func sendNewText(info: String) {
        /// If we received a new text
        if server != nil && server!.webSockets.count > 0 {
            for i in server!.webSockets {
                i.send(text: "text:" + info)
            }
        }
	}
	
	func sendNewWifi() {
		/// Don't know what data type to send
	}
	
	func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
		// A web socket connected, you can extract additional information from the handshake request
        
        if self.debug {
            self.log("\(webSocket.remoteEndpoint?.host ?? "") is trying to connect...")
        }
		
		if !verify_auth(webSocket.remoteEndpoint?.host ?? "") {
            if self.debug {
                self.log("\(webSocket.remoteEndpoint?.host ?? "") is not verified. Disconnecting.")
            }
			webSocket.close(immediately: true)
		}
		
		/*let battery_level = UIDevice.current.batteryLevel * 100
		
		webSocket.send(text: "battery:\(String(battery_level))")*/

		/// Backgrounding doesn't work with the next line uncommented
		//NotificationCenter.default.addObserver(self, selector: Selector(("sendNewBattery:")), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
	}

	func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
		// One of our web sockets disconnected
        if self.debug {
            self.log("Socket disconnected")
        }
	}

	func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
		// One of our web sockets sent us a message
        if message.payload.data != nil && self.debug {
            self.log("Received message: \(String(describing: message.payload.data))")
        }
	}
}


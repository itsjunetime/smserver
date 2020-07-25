//
//  SocketDelegate.swift
//  SMServer
//
//  Created by ian on 7/21/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

import Foundation
import Telegraph
import os

class SocketDelegate : ServerWebSocketDelegate {
	
	let server = Server()
	var watcher: IPCTextWatcher? = nil
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
	
	func sendNewBattery(percent: Int) {
		for i in server.webSockets {
			i.send(text: "battery:" + String(percent))
		}
	}
	
	func sendNewText(info: String) {
		for i in server.webSockets {
			i.send(text: "text:" + info)
		}
	}
	
	func sendNewWifi() {
		/// Don't know what data type to send
	}
	
	func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
		// A web socket connected, you can extract additional information from the handshake request
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


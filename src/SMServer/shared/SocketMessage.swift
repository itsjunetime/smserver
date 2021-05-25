class SocketMessage {
	let id: String?
	let command: APICommand
	let data: Any
	let incoming: Bool

	init(_ json: [String: Any], incoming: Bool) {
		id = json["id"] as? String
		command = str_to_command[json["command"] as? String ?? ""] ?? .Indecipherable
		data = {
			if json["id"] as? String == nil {
				return json["data"] as? [String:Any] ?? [String:Any]()
			}
			return json["params"] as? [String:Any] ?? [String:Any]()
		}()
		self.incoming = incoming
	}

	init(_ id: String?, command: APICommand, data: Any, incoming: Bool) {
		self.id = id
		self.command = command
		self.data = data
		self.incoming = incoming
	}

	static func typing(_ chat: String, active: Bool) -> SocketMessage {
		let data: [String:Any] = [
			"chat": chat,
			"active": active
		]

		return SocketMessage(nil, command: .Typing, data: data, incoming: false)
	}

	static func newMessage(_ msg: [String: Any]) -> SocketMessage {
		return SocketMessage(nil, command: .NewMessage, data: msg, incoming: false)
	}

	func json() -> [String:Any] {
		let cmd_str = str_to_command.first(where: { $0.1 == command })?.key ?? "indecipherable"
		var json = [
			"command": cmd_str,
			(incoming ? "params" : "data"): data
		]

		if let id = id {
			json["id"] = id
		}

		return json
	}
}

import Foundation
import Criollo

class ServerDelegate {
	let server = CRHTTPServer()
	let socket = SocketDelegate()
	let identity = Bundle.main.path(forResource: "identity", ofType: "pfx")
	let cert_pass = PKCS12Identity.pass  /// This is in a hidden file, not in the git repository, so that nobody can steal the private key of my cert.

	static let chat_delegate = ChatDelegate()
	static let sender: IWSSender = IWSSender.init()
	var watcher: IPCTextWatcher = IPCTextWatcher.sharedInstance()

	var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	var mark_when_read: Bool = UserDefaults.standard.object(forKey: "mark_when_read") as? Bool ?? true
	var restarted_recently: Bool = false

	var main_page: String = ""
	var main_page_style: String = ""
	var gatekeeper_page: String = ""
	var light_style: String = ""
	var nord_style: String = ""
	var fa_style: String = ""
	var fa_solid_style: String = ""
	var custom_style: String = ""
	let requests_page = """
	<!DOCTYPE html>
		<p>This is the requests page!</p>
		<p>Visit <a href="https://github.com/iandwelker/smserver/blob/master/docs/API.md">here</a> for information on how to use the API :)</p>
	</html>
	"""

	var authenticated_addresses = UserDefaults.standard.object(forKey: "authenticated_addresses") as? [String] ?? [String]()

	func loadFuncs() {
		self.loadFiles()

		self.watcher.setTexts = { value in
			self.sentOrReceivedNewText(value ?? "None")
		}

		self.watcher.setTyping = { vals in
			self.setPartyTyping(vals as? [String:Any] ?? [String:Any]())
		}

		self.watcher.sentTapback = { tapback, guid in
			self.sentTapback(tapback, guid: guid ?? "")
		}

		socket.watcher = self.watcher
		socket.authenticated_addresses = self.authenticated_addresses
		socket.verify_auth = self.checkIfAuthenticated

		/// Here we set up notification observers for when the network changes, so that we can automatically restart the server on the new network & with the new IP.
		/// This is kinda a hacky way sending the notification into a `CFNotificationCallback`, which then posts a notification in the `NSNotificationCenter`), but
		/// it is necessary. The `CFNotificationCallback` can't capture context, but the `NSNotificationCenter` callback can. We need to capture context for our purposes,
		/// so this seemed like the most efficient solution to accomplish that.

		let callback: CFNotificationCallback = { (nc, observer, name, object, info) in
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ianwelker.smserver.system.config.network_change"), object: nil)
		}

		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, callback,
										"com.apple.system.config.network_change" as CFString, nil, CFNotificationSuspensionBehavior.deliverImmediately)

		NotificationCenter.default.addObserver(self, selector: #selector(reloadServer(_:)), name: NSNotification.Name("ianwelker.smserver.system.config.network_change"), object: nil)
	}

	@objc func reloadServer(_: Notification) {
		if restarted_recently { return }

		Const.log("Disconnected from wifi, restarting server with current auth list...", debug: self.debug)

		restarted_recently = true
		let override_no_wifi: Bool = UserDefaults.standard.object(forKey: "override_no_wifi") as? Bool ?? false

		self.stopServers(clear_auth: false)

		if override_no_wifi || Const.getWiFiAddress() != nil {
			_ = self.startServers()
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
			self.restarted_recently = false
		})
	}

	func reloadVars() {
		self.debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
		self.loadFiles()
		ServerDelegate.chat_delegate.refreshVars()
		self.socket.refreshVars()
	}

	func loadFiles() {
		/// This sets the website page files to local variables
		let socket_port = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740

		let default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 100
		let default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 40
		let default_num_photos = UserDefaults.standard.object(forKey: "num_photos") as? Int ?? 40

		let subjects_enabled = UserDefaults.standard.object(forKey: "subjects_enabled") as? Bool ?? false
		let light_theme = UserDefaults.standard.object(forKey: "light_theme") as? Bool ?? false
		let nord_theme = UserDefaults.standard.object(forKey: "nord_theme") as? Bool ?? false

		self.debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false

		if let h = Bundle.main.url(forResource: "chats", withExtension: "html", subdirectory: "html"),
		   let s = Bundle.main.url(forResource: "style", withExtension: "css", subdirectory: "html"),
		   let g = Bundle.main.url(forResource: "gatekeeper", withExtension: "html", subdirectory: "html"),
		   let l = Bundle.main.url(forResource: "light_theme", withExtension: "css", subdirectory: "html"),
		   let n = Bundle.main.url(forResource: "nord_theme", withExtension: "css", subdirectory: "html"),
		   let fa = Bundle.main.url(forResource: "font_awesome", withExtension: "css", subdirectory: "html/fontawesome"),
		   let fs = Bundle.main.url(forResource: "fa_solid", withExtension: "css", subdirectory: "html/fontawesome") {
			do {
				/// Set up all the pages as multi-line string variables, set values within them.
				self.main_page = try String(contentsOf: h, encoding: .utf8)
					.replacingOccurrences(of: "var num_texts_to_load;", with: "var num_texts_to_load = \(default_num_messages);")
					.replacingOccurrences(of: "var num_chats_to_load;", with: "var num_chats_to_load = \(default_num_chats);")
					.replacingOccurrences(of: "var num_photos_to_load;", with: "var num_photos_to_load = \(default_num_photos);")
					.replacingOccurrences(of: "var socket_port;", with: "var socket_port = \(socket_port);")
					.replacingOccurrences(of: "var debug;", with: "var debug = \(self.debug);")
					.replacingOccurrences(of: "var subject;", with: "var subject = \(subjects_enabled);")
					.replacingOccurrences(of: "<!--light-->", with: light_theme ? "<link rel=\"stylesheet\" type=\"text/css\" href=\"style?light\">" : "")
					.replacingOccurrences(of: "<!--nord-->", with: nord_theme ? "<link rel=\"stylesheet\" type=\"text/css\" href=\"style?nord\">" : "")

				self.main_page_style = try String(contentsOf: s, encoding: .utf8)
				self.gatekeeper_page = try String(contentsOf: g, encoding: .utf8)
				self.light_style = try String(contentsOf: l, encoding: .utf8)
				self.nord_style = try String(contentsOf: n, encoding: .utf8)
				self.fa_style = try String(contentsOf: fa, encoding: .utf8)
				self.fa_solid_style = try String(contentsOf: fs, encoding: .utf8)
			} catch {
				Const.log("WARNING: ran into an error with loading the files, try again.", debug: debug, warning: true)
			}
		}

		/// Have to do custom style in a different do {} block, since it'll fail everything if the file doesn't exist/is empty
		do {
			self.custom_style = try String(contentsOf: Const.custom_css_path, encoding: .utf8)
		} catch {
			self.custom_style = ""
			Const.log("Could not load custom css file", debug: debug, warning: true)
		}
	}

	func startServers() -> Bool {
		let server_port = UserDefaults.standard.object(forKey: "port") as? Int ?? 8741
		let socket_port = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740

		if server.isListening {
			self.stopServers()
			Const.log("Server was already running, stopped.", debug: debug, warning: false)
		}

		if UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true {
			server.isSecure = true
			server.identityPath = identity
			server.password = cert_pass
		}

		server.add("/") { (req, res, _) in
			let ip = req.connection?.remoteAddress ?? ""
			res.setValue("text/html", forHTTPHeaderField: "Content-type")

			Const.log("GET main: \(ip)", debug: self.debug)

			res.send(self.checkIfAuthenticated(ras: ip) ? self.main_page : self.gatekeeper_page)
		}

		server.add("/requests") { (req, res, _) in
			/// There is no authentication handler here 'cause it handles that within parseAndReturn()
			/// since they send the password auth request to this subdirectory.
			/// This handler is part of the API, and mostly returns JSON info with some plain text mixed in.

			let address = req.connection?.remoteAddress ?? ""
			let query = req.query

			Const.log("GET /requests: \(address)", debug: self.debug)

			if query.count == 0 {
				/// If there are no parameters, return default blank page

				if !self.checkIfAuthenticated(ras: address) {
					res.setStatusCode(403, description: "Please authenticate")
					res.send("")
				} else {
					res.setValue("text/html", forHTTPHeaderField: "Content-type")
					res.send(self.requests_page)
				}
			} else {

				/// parseAndReturn() manages retrieving info for the API
				let response = self.parseAndReturn(params: query, address: address)

				if response[0] as? Int ?? 200 != 200 {
					res.setStatusCode(UInt(response[0] as? Int ?? 200), description: response[1] as? String ?? "")
				}

				Const.log("Returning from /requests", debug: self.debug)
				res.send(response[1] as? String ?? "")
			}
		}

		server.add("/data") { (req, res, _) in
			/// This handler returns attachment data and profile/attachment/photo images.
			let ip = req.connection?.remoteAddress ?? ""
			Const.log("GET data: \(ip)", debug: self.debug)

			if !self.checkIfAuthenticated(ras: ip) {
				/// Return nil if they haven't authenticated
				res.setStatusCode(403, description: "Please authenticate")
				res.send("")
				return
			}

			Const.log("returning data", debug: self.debug)

			let f = req.query.keys.first

			/// Handle different types of requests
			if f == "chat_id" {
				/// This gets profile pictures. The value for this key has to be the `chat_identifier` of the profile picture you want.

				let q = req.query
				let data = ServerDelegate.chat_delegate.returnImageData(chat_id: q["chat_id"] ?? "")

				res.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
				if data == nil { res.setStatusCode(404, description: "No profile image for chat_id \(q["chat_id"] ?? "")") }
				res.send(data ?? Data.init(capacity: 0))
			} else if f == "path" {
				/// This gets attachments. The value for this key must be the path at which the attachment resides,
				/// minus the prefix of `/private/var/mobile/Library/SMS/`

				let info = ServerDelegate.chat_delegate.getAttachmentDataFromPath(path: req.query["path"] ?? "")

				if info[0] as? Data == nil || (info[0] as! Data).isEmpty {
					res.setStatusCode(404, description: "No attachment was found for this path")
				} else {
					res.setValue(info[1] as! String, forHTTPHeaderField: "Content-Type")
					res.setValue("inline; filename=\(req.query["path"]?.split(separator: "/").last ?? "")", forHTTPHeaderField: "Content-Disposition")
				}
				res.send(info[0] as? Data ?? Data.init(capacity: 0))
			} else if f == "photo" {
				/// This gets an image from the camera roll. The value for this key must be the path at which the image resides,
				/// minus the prefix of `/var/mobile/Media/`

				res.setValue("image/png", forHTTPHeaderField: "Content-Type")
				let data = ServerDelegate.chat_delegate.getPhotoDatafromPath(path: req.query["photo"] ?? "")

				if data.isEmpty {
					res.setStatusCode(404, description: "No photo exists at the specified URL")
				}

				res.send(data)
			} else {
				//if they don't have any of the above parameters, return nothing.
				res.setStatusCode(404, description: "There is no functionality in the API that implements these URL query parameters")
				res.send("")
			}
		}

		server.add("/send") { (req, res, _) in
			/// This handles a post request to send a text
			let ip = req.connection?.remoteAddress ?? ""
			Const.log("POST send: \(ip)", debug: self.debug)

			if !self.checkIfAuthenticated(ras: ip) {
				res.setStatusCode(403, description: "Please authenticate")
				res.send("")
				return
			}

			if req.method == .post {

				/// send text
				let params = req.body as? Dictionary<String, Any> ?? [String:Any]()
				var files_to_fix = [CRUploadedFile]()
				var files = [String]()

				if let f = req.files?["attachments"] as? [CRUploadedFile] {
					files_to_fix = f
				} else if let f = req.files?["attachments"] as? CRUploadedFile {
					files_to_fix = [f]
				}

				let fm = FileManager.default

				for file in files_to_fix {

					var moved_file = true
					let temp = file.temporaryFileURL.path
					let newFilePath = "\(temp.prefix(upTo: temp.lastIndex(of: "/") ?? temp.endIndex))/\(file.name.replacingOccurrences(of: " ", with: "_"))"

					/// Move file from temporary path to new type so that it displays original name and extension when sent
					if fm.fileExists(atPath: newFilePath) {
						do {
							try fm.removeItem(atPath: newFilePath)
						} catch {
							Const.log("Couldn't remove old file from: \(newFilePath)", debug: self.debug, warning: true)
							moved_file = false
						}
					}

					if moved_file {
						do {
							try fm.moveItem(at: file.temporaryFileURL, to: URL(fileURLWithPath: newFilePath))
						} catch {
							Const.log("Couldn't move uploaded file to \(newFilePath)", debug: self.debug, warning: true)
						}
					}

					/// Append to files array
					files.append(moved_file ? newFilePath : file.temporaryFileURL.path)
				}

				let code = self.sendText(params: params, new_files: files)
				var fail_msg = ""

				if code != 200 {
					fail_msg = code == 400 ? "Please include either `body`, `subject`, `photos`, or `attachments` in your POST request" : "Failed to send text; unknown reason."
					res.setStatusCode(UInt(code), description: fail_msg)
				}

				Const.log("Returning from sending text", debug: self.debug)
			} else if req.method == .get {
				let send_response = self.sendGetRequest(params: req.query)

				if let code: Int = send_response[0] as? Int, code != 200 {
					res.setStatusCode(UInt(code), description: send_response[0] as? String ?? "")
				}
			}

			res.send("")
		}

		server.add("/style") { (req, res, _) in
			/// Returns the style.css file as text
			let ip = req.connection?.remoteAddress ?? ""

			Const.log("GET style: \(ip)", debug: self.debug)

			if !self.checkIfAuthenticated(ras: ip) {
				res.setStatusCode(403, description: "Please authenticate")
				res.send("")
				return
			}

			let s = Array(req.query.keys)[0]
			res.setValue("text/css", forHTTPHeaderField: "Content-Type")

			if s == "main" {
				res.send(self.main_page_style)
			} else if s == "custom" {
				res.send(self.custom_style)
			} else if s == "light" {
				res.send(self.light_style)
			} else if s == "nord" {
				res.send(self.nord_style)
			} else if s == "fa_solid" {
				res.send(self.fa_solid_style)
			} else if s == "font_awesome" {
				res.send(self.fa_style)
			}
		}

		server.add("/webfonts") { (req, res, _) in
			/// Gets the fonts necessary for fontawesome
			let ip = req.connection?.remoteAddress ?? ""

			Const.log("GET webfonts: \(ip)", debug: self.debug)

			if !self.checkIfAuthenticated(ras: ip) {
				res.setStatusCode(403, description: "Please authenticate")
				res.send("")
				return
			}

			let font = Array(req.query.keys)[0]

			if let f = Bundle.main.url(forResource: font, withExtension: "", subdirectory: "html/webfonts") {
				do {
					let font_data = try Data.init(contentsOf: f)
					res.send(font_data)
				} catch {
					Const.log("WARNING: Can't get font for \(font)", debug: self.debug, warning: true)
					res.send("")
				}
			} else {
				res.send("")
			}
		}

		server.add("/favicon.ico") { (req, res, next) in
			/// Returns the app icon. Doesn't have authentication so that it still appears when you're at the gatekeeper.
			let data = UIImage(named: "favicon")?.pngData() ?? Data.init(capacity: 0)
			res.setValue("image/png", forHTTPHeaderField: "Content-Type")
			res.send(data)
		}

		Const.log("Got past adding all the handlers.", debug: self.debug)

		server.startListening(nil, portNumber: UInt(server_port))
		socket.startServer(port: socket_port)

		return isRunning()
	}

	func stopServers(clear_auth: Bool = true) {
		/// Stops the server & and de-authenticates all ip addresses

		self.server.stopListening()
		self.socket.stopServer()
		Const.log("Stopped Server", debug: self.debug)

		if clear_auth { self.authenticated_addresses = [String]() }
	}

	func isRunning() -> Bool {
		return server.isListening && socket.server != nil && socket.server?.isRunning ?? false
	}

	func checkIfAuthenticated(ras: String) -> Bool {
		/// This checks if the ip address `ras` has already authenticated with the host
		let require_authentication = UserDefaults.standard.object(forKey: "require_auth") as? Bool ?? true

		return !require_authentication || self.authenticated_addresses.contains(ras)
	}

	func encodeToJson(object: Any, title: String) -> String {
		/// This encodes `object` (normally like an array of dictionary or dictionary of dictionaries) to JSON, with the title of `title`

		guard let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
			return ""
		}
		var data_string = String(decoding: data, as: UTF8.self)
		data_string = "{ \"\(title)\": \(data_string)\n}"
		return data_string
	}

	func sendText(params: [String:Any], new_files: [String]) -> Int {

		let body: String = params["text"] as? String ?? ""
		var address: String = params["chat"] as? String ?? ""
		let subject: String = params["subject"] as? String ?? ""
		var files = new_files

		if params["photos"] != nil {
			let ph = (params["photos"] as? String ?? "").split(separator: ":")
			for i in ph {
				files.append(Const.photo_address_prefix + String(i))
			}
		}

		if address.prefix(1) == "+" { /// Make sure there are no unnecessary characters like parenthesis
			address = "+\(address.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())"
		}

		/// Make sure there's actually some content
		if body != "" || files.count > 0 || subject != "" {
			/// Send the information the obj-c function
			let response = ServerDelegate.sender.sendIPCText(body, withSubject: subject, toAddress: address, withAttachments: files)
			return response ? 200 : 503
		}

		return 400 /// HTTP 400 status code, as in they sent some information that won't send a text
	}

	func sendGetRequest(params: [String:String]) -> [Any] {

		if Const.api_tap_vals.contains(params.keys.first ?? "") {

			guard let req = params[Const.api_tap_req], let guid = params[Const.api_tap_guid], let chat = params[Const.api_tap_chat] else {
				return [400, "Please include parameters 'tapback', 'tap_guid', and 'tap_in_chat' in your request"]
			}

			var reaction: Int = (Int(req) ?? -1) + 2000 /// reactions are 2000 - 2005
			let remove = (params[Const.api_tap_rem] ?? "false") == "true"

			guard reaction < 2005 && reaction > 2000 else {
				return [400, "tapback value must be at least 0 and no greater than 5"]
			}

			if remove { reaction += 1000 }

			let ret = ServerDelegate.sender.sendTapback(reaction as NSNumber, forGuid: guid, inChat: chat)

			if !ret {
				return [503, "Could not send tapback; unknown reason"]
			}

			return [200, ""]
		} else if Const.api_del_vals.contains(params.keys.first ?? "") {
			/// Deletes a conversation or text
			guard let chat: String = params[Const.api_del_chat] else {
				return [400, "Please enter at least one identifier"]
			}

			let text: String = params[Const.api_del_text] ?? ""

			let ret = ServerDelegate.sender.removeObject(chat, text: text)

			if !ret {
				return [503, "Failed to remove object; unknown reason"]
			}

			return [200, ""]
		}

		return [406, "No api endpoint exists for url query parameters"]
	}

	func parseAndReturn(params: [String:String], address: String = "") -> [Any] {
		/// This function handles all the requests to the /requests subdirectory, and returns stuff like conversations, messages, and can send texts.
		if self.debug {
			for i in Array(params.keys) {
				Const.log("parsing \(i) and \(String(describing: params[i]))", debug: self.debug)
			}
		}
		if params.keys.first == "password" {
			/// If they're sending over the password to authenticate
			let password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
			/// If they sent the correct password
			if params.values.first == password {
				if !authenticated_addresses.contains(address) {
					authenticated_addresses.append(address)
				}
				return [200, "true"]
			}

			/// sleep to ensure that they can't brute-force it
			sleep(2)

			/// default
			return [200, "false"]
		}
		/// If they're not authenticated
		if !self.checkIfAuthenticated(ras: address) {
			return [403, "Please authenticate"]
		}

		let default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 100
		let default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 40
		let default_num_photos = UserDefaults.standard.object(forKey: "num_photos") as? Int ?? 40

		let f = Array(params.keys)[0] as String

		if Const.api_msg_vals.contains(f) {
			/// requesting messages from a specific person
			var person = params[Const.api_msg_req] ?? ""

			if (params[Const.api_msg_read] == nil && self.mark_when_read) || (params[Const.api_msg_read] != nil && params[Const.api_msg_read] == "true") {
				/// yeah so this does return a `BOOL` but I don't really know what to do if it returns `NO`...
				ServerDelegate.sender.markConvo(asRead: person)
			}

			let num_texts = Int(params[Const.api_msg_num] ?? String(default_num_messages)) ?? default_num_messages
			let offset = Int(params[Const.api_msg_off] ?? "0") ?? 0
			let from = Int(params[Const.api_msg_from] ?? "0") ?? 0 /// 0 for either, 1 for me, 2 for them
			person = person.replacingOccurrences(of: "\"", with: "") /// In case they decide to capture it in quotes

			Const.log("selecting person: \(person), num: \(num_texts)", debug: self.debug)

			let texts_array = ServerDelegate.chat_delegate.loadMessages(num: person, num_items: num_texts, offset: offset, from: from)
			let texts = encodeToJson(object: texts_array, title: "texts")

			return [200, texts]
		} else if Const.api_chat_vals.contains(f) {
			/// Requesting most recent conversations

			let chats_offset = Int(params[Const.api_chat_off] ?? "0") ?? 0
			let num_texts = Int(params[Const.api_chat_req] ?? String(default_num_chats)) ?? default_num_chats
			Const.log("num chats: \(num_texts), offset: \(chats_offset)", debug: self.debug)

			let chats_array = ServerDelegate.chat_delegate.loadChats(num_to_load: num_texts, offset: chats_offset)
			let chats = encodeToJson(object: chats_array, title: "chats")

			return [200, chats]
		} else if f == Const.api_name_req {
			/// Requesting name for a chat_id

			let chat_id = params[Const.api_name_req] ?? ""
			let name = ServerDelegate.chat_delegate.getDisplayName(chat_id: chat_id)

			return [200, name]
		} else if Const.api_search_vals.contains(f) {
			/// Searching for a specific term

			let case_sensitive = (params[Const.api_search_case] ?? "false") == "true"
			let bridge_gaps = (params[Const.api_search_bridge] ?? "true") == "true"
			let group_by_time = (params[Const.api_search_group] ?? "time") == "time" /// if false, group by person.
			let term = params[Const.api_search_req] ?? ""

			let responses = ServerDelegate.chat_delegate.searchForString(term: term , case_sensitive: case_sensitive, bridge_gaps: bridge_gaps, group_by_time: group_by_time)
			let matches = encodeToJson(object: responses, title: "matches")

			return [200, matches]
		} else if Const.api_photo_vals.contains(f) {
			/// Retrieving most recent photos
			let most_recent = (params[Const.api_photo_recent] ?? "true") == "true"
			let offset = Int(params[Const.api_photo_off] ?? "0") ?? 0
			let num = Int(params[Const.api_photo_req] ?? String(default_num_photos)) ?? default_num_photos

			let ret_val = ServerDelegate.chat_delegate.getPhotoList(num: num, offset: offset, most_recent: most_recent)
			let photos = encodeToJson(object: ret_val, title: "photos")

			return[200, photos]
		}

		Const.log("WARNING: We haven't implemented this functionality yet, sorry :/", debug: self.debug, warning: true)
		return [404, "There is no functionality in the API that implements these URL query parameters"]
	}

	func sentOrReceivedNewText(_ guid: String) {
		/// Is called when you receive a new text; Tells the socket to send a notification to all connected that you received a new text
		guard server.isListening && socket.server?.webSocketCount ?? 0 > 0 else { return }

		let text = ServerDelegate.chat_delegate.getTextByGUID(guid);
		let json = encodeToJson(object: text, title: "text")

		socket.sendNewText(info: json)
	}

	func sentTapback(_ tapback: Int32, guid: String) {
		guard server.isListening && socket.server?.webSocketCount ?? 0 > 0 else { return }

		let tb = ServerDelegate.chat_delegate.getTapbackInformation(tapback, guid: guid)
		let json = encodeToJson(object: tb, title: "text")

		socket.sendNewText(info: json)
	}

	func setPartyTyping(_ vals: [String:Any]) {
		/// Theoretically called when someone else starts typing. Theoretically.
		self.socket.sendTyping(vals["chat"] as! String, typing: vals["typing"] as! NSNumber == 1)
	}
}

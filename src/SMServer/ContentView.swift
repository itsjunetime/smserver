import SwiftUI
import Criollo
import Telegraph
import Photos
import os

struct ContentView: View {
    let server = CRHTTPServer()
	let socket = SocketDelegate()
    let prefix = "SMServer_app: "
    let geo_width: CGFloat = 0.6
    let font_size: CGFloat = 25
    let identity = Bundle.main.path(forResource: "identity", ofType: "pfx")
    let cert_pass = "smserver"
    
    @State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    @State var authenticated_addresses = UserDefaults.standard.object(forKey: "authenticated_addresses") as? Array<String> ?? [String]()
    @State var custom_css = UserDefaults.standard.object(forKey: "custom_css") as? String ?? ""
    @State var port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
    @State var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
	@State var socket_port: Int = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740
    @State var light_theme: Bool = UserDefaults.standard.object(forKey: "light_theme") as? Bool ?? false
    @State var secure: Bool = UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true
    @State var mark_when_read: Bool = UserDefaults.standard.object(forKey: "mark_when_read") as? Bool ?? true
    
    @State var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    @State var view_settings = false
    @State var server_running = false
    @State var alert_connected = false
    @State var has_root = false
    @State var show_picker = false
    
    static let chat_delegate = ChatDelegate()
    @State var s = Sender()
    @State var watcher: IPCTextWatcher = IPCTextWatcher.sharedInstance()
    
    let custom_css_path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("smserver_custom.css")
    let photos_prefix = "/private/var/mobile/Media/DCIM/"
    
    var requests_page = """
    <!DOCTYPE html>
        <body style="background-color: #222;">
            <p style="color: #DDD; font-family: Verdana; font-size: 24px; padding: 20px;">
                This is the requests page! Thanks for visiting :)
            </p>
        </body>
    </html>
    """
    @State var main_page =
    """
    """
    @State var main_page_style =
    """
    """
    @State var main_page_script =
    """
    """
    @State var gatekeeper_page =
    """
    """
    @State var custom_style =
    """
    """
    @State var light_style =
    """
    """
    
    func log(_ s: String) {
        /// This logs to syslog
        os_log("%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, self.prefix, s)
    }
    
    func loadServer(port_num: UInt16) {
        /// This starts the server at port $port_num
        
        self.debug ? self.log("Loading server at port \(String(port_num))") : nil
        
        if server.isListening {
            self.stopServer()
            self.debug ? self.log("Server was already running, stopped.") : nil
        }
        
        /// The mobileSMS App must be running to send texts in the background, so we start it with this.
        self.s.launchMobileSMS()
        
        if self.debug {
            self.log("launched MobileSMS")
        }
        
        if UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true {
            server.isSecure = true
            server.identityPath = identity
            server.password = cert_pass
        }
        
        server.add("/") { (req, res, next) in
            let ip = req.connection?.remoteAddress ?? ""
            res.setValue("text/html", forHTTPHeaderField: "Content-type")
            
            if self.debug {
                self.log("GET main: " + ip)
            }
            
            if self.checkIfAuthenticated(ras: ip) {
                res.send(self.main_page)
            } else {
                res.send(self.gatekeeper_page)
            }
        }
        
        server.add("/requests") { (req, res, next) in
            /// There is no authentication handler here 'cause it handles that within parseAndReturn()
            /// since they send the password auth request to this subdirectory
            
            /// This handler is part of the API, and returns JSON info.
            
            if self.debug {
                self.log("Getting requests..")
            }
            
            var query = req.query
            
            if query.count == 0 {
                /// If there are no parameters, return default blank page
                
                res.setValue("text/html", forHTTPHeaderField: "Content-type")
                res.send(self.requests_page)
            } else {
                
                let address = req.connection?.remoteAddress ?? ""
                
                if self.debug {
                    self.log("GET /requests: \(address)")
                }
                
                if ((req.env["QUERY_STRING"]?.contains("%2B") ?? false || req.env["QUERY_STRING"]?.contains("+") ?? false) && (query["name"] != nil || query["person"] != nil)) {
                    for i in req.env["QUERY_STRING"]!.split(separator: "&") {
                        let p = String(String(i).split(separator: "=")[0])
                        let index = String(i).index(String(i).firstIndex(of: "=") ?? String(i).startIndex, offsetBy: 1)
                        let v = String(String(i).suffix(from: index))
                        query[p]? = v.replacingOccurrences(of: "%2B", with: "+")
                    } /// So that `%2B` in the URL turns to `+` for the right parameters
                }
                
                /// parseAndReturn() manages retrieving info for the API
                let response = self.parseAndReturn(params: query, address: address)
                
                if self.debug {
                    self.log("Returning from /requests")
                }
                
                res.send(response)
            }
        }
		
        server.add("/data") { (req, res, next) in
            /// This handler returns attachment data and profile/attachment/photo images.
            let ip = req.connection?.remoteAddress ?? ""
   
			if self.debug {
				self.log("GET data: " + ip)
			}
			
			if !self.checkIfAuthenticated(ras: ip) {
                /// Return nil if they haven't authenticated
                res.send("")
                return
			}
			
			if self.debug {
				self.log("returning data")
			}
			
            let f = req.query.keys.first
			
            /// Handle different types of requests
			if f == "chat_id" {
                
                var q = req.query
                
                if (req.env["QUERY_STRING"]?.contains("%2B") ?? false || req.env["QUERY_STRING"]?.contains("+") ?? false) {
                    for i in req.env["QUERY_STRING"]!.split(separator: "&") {
                        let p = String(String(i).split(separator: "=")[0])
                        let index = String(i).index(String(i).firstIndex(of: "=") ?? String(i).startIndex, offsetBy: 1)
                        let v = String(String(i).suffix(from: index))
                        q[p]? = v.replacingOccurrences(of: "%2B", with: "+")
                    } /// So that `%2B` in the URL turns to `+` for the right parameters instead of just being filtered out
                }
                
                res.setValue("image/jpeg", forHTTPHeaderField: "Content-type")
                res.send(ContentView.chat_delegate.returnImageData(chat_id: q["chat_id"] ?? ""))
			} else if f == "path" {
				
                let dataResponse = ContentView.chat_delegate.getAttachmentDataFromPath(path: req.query["path"] ?? "")
                let type = ContentView.chat_delegate.getAttachmentType(path: req.query["path"] ?? "")
				
                res.setValue(type, forHTTPHeaderField: "Content-type")
                res.send(dataResponse)
			} else if f == "photo" {

                res.setValue("image/png", forHTTPHeaderField: "Content-type")
                res.send(ContentView.chat_delegate.getPhotoDatafromPath(path: req.query["photo"] ?? ""))
            } else {
			
                //if they don't have any of the above parameters, return nothing.
                res.send("")
            }
        }
        
        server.add("/send") { (req, res, next) in
            /// This handles a post request to send a text
            let ip = req.connection?.remoteAddress ?? ""
            
            if self.debug {
                self.log("POST uploads: " + ip)
            }
            
            if !self.checkIfAuthenticated(ras: ip) {
                res.send("")
                return
            }
            
            /// send text
            let params = req.body as! Dictionary<String, Any> /// That's what is
            var files_to_fix = [CRUploadedFile]()
            var files = [String]()
            
            if let f = req.files?["attachments"] as? [CRUploadedFile] {
                for i in f {
                    files_to_fix.append(i)
                }
            } else if let f = req.files?["attachments"] as? CRUploadedFile {
                files_to_fix.append(f)
            }
            
            let fm = FileManager.default
            
            for file in files_to_fix {
                do {
                    /// get info about uploaded file
                    let attr = try fm.attributesOfItem(atPath: file.temporaryFileURL.path)
                    let fileSize = attr[FileAttributeKey.size] as! UInt64
                    
                    /// Don't send file if it is empty; fixes an issue where it would sometimes think null files were being uploaded?
                    if fileSize == 0 { continue }
                } catch {
                    self.log("couldn't get filesize")
                }
                
                let temp = file.temporaryFileURL.path
                let newFilePath = temp.prefix(upTo: temp.lastIndex(of: "/") ?? temp.endIndex) + "/" + file.name.replacingOccurrences(of: " ", with: "_")
                
                /// Move file from temporary path to new type so that it displays original name and extension when sent
                if fm.fileExists(atPath: newFilePath) {
                    do {
                        try fm.removeItem(atPath: newFilePath)
                    } catch {
                        self.log("Couldn't remove file from path: \(newFilePath), for whatever reason")
                    }
                }
                do {
                    try fm.moveItem(at: file.temporaryFileURL, to: URL(fileURLWithPath: newFilePath))
                } catch {
                    self.log("failed to move file; won't send text")
                }
                
                /// Append to files array
                files.append(newFilePath)
            }
            
            let send = self.sendText(params: params, new_files: files)
            
            if self.debug {
                self.log("Returning from sending text")
            }
            
            res.send(send ? "true" : "false")
        }
        
        server.add("/style.css") { (req, res, next) in
            /// Returns the style.css file as text
            let ip = req.connection?.remoteAddress ?? ""
            
            if self.debug {
                self.log("GET style.css: \(ip)")
            }
            
            if !self.checkIfAuthenticated(ras: ip) {
                res.send("")
                return
            }
            
            res.setValue("text/css", forHTTPHeaderField: "Content-type")
            res.send(self.main_page_style)
        }
        
        server.add("/custom.css") { (req, res, next) in
            /// Returns the custom css file as text
            let ip = req.connection?.remoteAddress ?? ""
            
            if self.debug {
                self.log("GET /custom.css: \(ip)")
            }
            
            if !self.checkIfAuthenticated(ras: ip) {
                res.send("")
                return
            }
            
            res.setValue("text/css", forHTTPHeaderField: "Content-type")
            res.send(self.custom_style)
        }
        
        server.add("/light.css") { (req, res, next) in
            /// returns the light theme css file as text
            let ip = req.connection?.remoteAddress ?? ""
            
            if self.debug {
                self.log("GET /light.css: \(ip)")
            }
            
            if !self.checkIfAuthenticated(ras: ip) {
                res.send("")
                return
            }
            
            res.setValue("text/css", forHTTPHeaderField: "Content-type")
            res.send(self.light_style)
        }
        
        server.add("/favicon.ico") { (req, res, next) in
            /// Returns the app icon. Doesn't have authentication so that it still appears when you're at the gatekeeper.
            let data = UIImage(named: "favicon")?.pngData() ?? Data.init(capacity: 0)
            res.setValue("image/png", forHTTPHeaderField: "Content-type")
            res.send(data)
        }
        
        if self.debug {
            self.log("Got past adding all the handlers.")
        }
        
        let port = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
        server.startListening(nil, portNumber: UInt(port) ?? 8741)
		
        /// Start the websocket
		socket.startServer(port: self.socket_port)
		
        self.server_running = server.isListening
        
        if self.debug {
            self.log("Successfully started server and launched MobileSMS")
        }
    }
    
    func sendText(params: [String:Any], new_files: [String]) -> Bool {
        
        var body = ""
        var address = ""
        var subject = ""
        var files = new_files
        
        /// Get text and body of the text
        for (key, value) in params {
            if let val = value as? String {
                if key == "text" {
                    body = val
                } else if key == "chat" {
                    address = val
                } else if key == "subject" {
                    subject = val
                } else if key == "photos" {
                    let ph = val.split(separator: ":")
                    if ph.count > 0 {
                        for i in ph {
                            files.append(self.photos_prefix + String(i))
                        }
                    }
                }
            }
        }
        
        if address.prefix(1) == "+" { /// Make sure there are no unnecessary characters like parenthesis
			address = "+" + address.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
		}
        
        /// Make sure there's actually some content
        if !(body == "" && files.count == 0) {
            /// Send the information the obj-c function
            self.s.sendIPCText(body, toAddress: address, withAttachments: files)
			
            return true
        } else {
            return false
        }
    }
    
    func startBackgroundTask() {
        /// This starts the background task
        
        DispatchQueue.global().async {
            if self.debug {
                self.log("started background task...")
            }
            
            self.backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                if UIApplication.shared.applicationState == .background {
                    if self.debug {
                        self.log("relaunching app...")
                    }
                    /// this is the completion handler, so whenever the background task is killed,
                    /// it just calls an IPC function in libsmserver to restart the app, so it's never actually killed.
                    self.s.relaunchApp()
                } else {
                    if self.debug {
                        self.log("Not in background, invalidating background task.")
                    }
                    self.backgroundTask = .invalid
                }
            })
        }
    }
    
    func endBackgroundTask() {
        if self.debug {
            self.log("Called endBackgroundTask()")
        }
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
    }
    
    func loadFiles() {
        /// This sets the website page files to local variables
        
        let default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 200
        let default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 60
        let default_num_photos = UserDefaults.standard.object(forKey: "num_photos") as? Int ?? 30
        
        self.debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
        self.mark_when_read = UserDefaults.standard.object(forKey: "mark_when_read") as? Bool ?? true
        
        self.light_theme = UserDefaults.standard.object(forKey: "light_theme") as? Bool ?? false
        
        if let h = Bundle.main.url(forResource: "chats", withExtension: "html", subdirectory: "html"),
        let s = Bundle.main.url(forResource: "style", withExtension: "css", subdirectory: "html"),
        let g = Bundle.main.url(forResource: "gatekeeper", withExtension: "html", subdirectory: "html"),
        let l = Bundle.main.url(forResource: "light_theme", withExtension: "css", subdirectory: "html") {
            do {
                /// Set up all the pages as multi-line string variables, set values within them.
                self.main_page = try String(contentsOf: h, encoding: .utf8)
                    .replacingOccurrences(of: "var num_texts_to_load;", with: "var num_texts_to_load = \(default_num_messages);")
                    .replacingOccurrences(of: "var num_chats_to_load;", with: "var num_chats_to_load = \(default_num_chats);")
                    .replacingOccurrences(of: "var num_photos_to_load;", with: "var num_photos_to_load = \(default_num_photos);")
					.replacingOccurrences(of: "var socket_port;", with: "var socket_port = \(String(socket_port));")
                    .replacingOccurrences(of: "<!--light-->", with: self.light_theme ? "<link rel=\"stylesheet\" type=\"text/css\" href=\"light.css\">" : "")
                    .replacingOccurrences(of: "var debug;", with: "var debug = \(self.debug ? "true" : "false");")
					
                self.main_page_style = try String(contentsOf: s, encoding: .utf8)
                self.gatekeeper_page = try String(contentsOf: g, encoding: .utf8)
                self.light_style = try String(contentsOf: l, encoding: .utf8)
            } catch {
                self.log("WARNING: ran into an error with loading the files, try again.")
            }
        }
        
        /// Have to do custom style in a different do {} block, since it'll fail everything if the file doesn't exist/is empty
        do {
            self.custom_style = try String(contentsOf: self.custom_css_path, encoding: .utf8)
        } catch {
            self.log("Could not load custom css file")
            self.custom_style = ""
        }
    }
    
    func setNewestTexts(_ chat_id: String) -> Void {
        /// Is called when you receive a new text; Tells the socket to send a notification to all connected that you received a new text
		socket.sendNewText(info: chat_id)
    }
    
    func checkIfAuthenticated(ras: String) -> Bool {
        /// This checks if the ip address $ras has already authenticated with the host
        
        let require_authentication = UserDefaults.standard.object(forKey: "require_auth") as? Bool ?? true
        
        if !require_authentication { return true }
        
        var clear = false
        
        for i in self.authenticated_addresses {
            if i == ras {
                clear = true
            }
        }
        
        return clear
    }
    
    func encodeToJson(object: Any, title: String) -> String {
        /// This encodes $object (normally like an array of dictionary or dictionary of dictionaries) to JSON, with the title of $title
        
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
            return ""
        }
        var data_string = String(decoding: data, as: UTF8.self)
        data_string = "{ \"\(title)\": \(data_string)\n}"
        return data_string
    }
    
    func parseAndReturn(params: [String:String], address: String = "") -> String {
        /// This function handles all the requests to the /requests subdirectory, and returns stuff like conversations, messages, and can send texts.
        
        if self.debug {
            for i in Array(params.keys) {
                self.log("parsing \(i) and \(String(describing: params[i]))")
            }
        }
        
        if Array(params.keys)[0] == "password" {
            /// If they're sending over the password to authenticate
            let password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
        
            if self.debug {
                self.log("comparing " + Array(params.values)[0] + " to " + password)
            }
            /// If they sent the correct password
            if Array(params.values)[0] == password {
                var already_in = false;
                for i in authenticated_addresses {
                    if i == address {
                        already_in = true
                    }
                }
                if !already_in {
                    authenticated_addresses.append(address)
                }
                return "true"
            } else { /// if they didn't send the correct password
                return "false"
            }
        }
        
        /// If they're not authenticated
        if !self.checkIfAuthenticated(ras: address) {
            return ""
        }
        
        let default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 100
        let default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 40
		let default_num_photos = UserDefaults.standard.object(forKey: "num_photos") as? Int ?? 40
        
        var person = ""
		var chat_id = ""
		
        var num_texts = 0
        var offset = 0
        
        let f = Array(params.keys)[0]
        
        if f == "person" || f == "num" || f == "offset" {
            /// requesting messages from a specific person
            person = params["person"] ?? ""
            
            num_texts = default_num_messages
            if params["num"] != nil {
                num_texts = Int(params["num"] ?? String(default_num_chats)) ?? default_num_chats
            }
            if params["offset"] != nil {
                offset = Int(params["offset"] ?? "0") ?? 0
            }
            
            if self.debug {
                self.log( "selecting person: " + person + ", num: " + String(num_texts))
            }
            
            if person.contains("\"") { /// Just in case, I guess?
                person = person.replacingOccurrences(of: "\"", with: "")
            }
			
            /// This really doesn't look right but I think that's just what it is
            if self.mark_when_read {
                self.s.markConvo(asRead: person)
            }
            
            let texts_array = ContentView.chat_delegate.loadMessages(num: person, num_items: num_texts, offset: offset)
            let texts = encodeToJson(object: texts_array, title: "texts")
            return texts
            
        } else if f == "chat" || f == "num_chats"  || f == "chats_offset" {
            /// Requesting most recent conversations
            num_texts = default_num_chats
            var chats_offset = 0
            if params["num_chats"] != nil {
                num_texts = Int(params["num_chats"] ?? String(default_num_chats)) ?? default_num_chats
            }
            if params["chats_offset"] != nil {
                chats_offset = Int(params["chats_offset"] ?? "0") ?? 0
            }
            
            if self.debug {
                self.log("num chats: \(num_texts)")
                self.log("chats offset: \(chats_offset)")
            }
            
            let chats_array = ContentView.chat_delegate.loadChats(num_to_load: num_texts, offset: chats_offset)
            let chats = encodeToJson(object: chats_array, title: "chats")
            
            return chats
            
        } else if f == "name" {
            /// Requesting name for a chat_id
            chat_id = params["name"] ?? ""
            
            let name = ContentView.chat_delegate.getDisplayName(chat_id: chat_id)
            return name
            
        } else if f == "search" || f == "case_sensitive" || f == "bridge_gaps" {
            /// Searching for a specific term
			var case_sensitive = false
			var bridge_gaps = true
			
			let term = params["search"]
			if params["case_sensitive"] != nil {
				case_sensitive = params["case_sensitive"] == "true"
			}
			if params["bridge_gaps"] != nil {
				bridge_gaps = params["bridge_gaps"] == "true"
			}
			let responses = ContentView.chat_delegate.searchForString(term: term ?? "", case_sensitive: case_sensitive, bridge_gaps: bridge_gaps)
			
			let return_val = encodeToJson(object: responses, title: "Texts that match '" + (term ?? "nil") + "'")
			
			return return_val
		} else if f == "photos" || f == "photo_offset" || f == "most_recent" {
            /// Retrieving most recent photos
			var most_recent = true
			var offset = 0
			
			let num = Int(params["photos"] ?? String(default_num_photos)) ?? default_num_photos
			
			if params["photo_offset"] != nil {
				offset = Int(params["photo_offset"] ?? "0") ?? 0
			}
			if params["most_recent"] != nil {
				most_recent = params["most_recent"] == "true"
			}
			
			let ret_val = ContentView.chat_delegate.getPhotoList(num: num, offset: offset, most_recent: most_recent)
			
			return encodeToJson(object: ret_val, title: "photos")
		}
        
        self.debug ? print("We haven't implemented this functionality yet, sorry :/") : nil
        
        return ""
    }
    
    func stopServer() {
        /// Stops the server & and de-authenticates all ip addresses
        
        self.server.stopListening()
		socket.stopServer()
        if self.debug {
            self.log("Stopped Server")
        }
        self.authenticated_addresses = [String]()
        server_running = server.isListening
    }
	
	func loadFuncs() {
		/// All the functions that run on scene load
		
		self.loadFiles()
		
		self.has_root = self.s.setUID() == uid_t(0)
        
		self.watcher.setTexts = { value in
			self.setNewestTexts(value ?? "None")
		}
        self.watcher.setBattery = {
            self.socket.sendNewBattery()
        }
		
		socket.watcher = self.watcher
		socket.authenticated_addresses = self.authenticated_addresses
		socket.verify_auth = self.checkIfAuthenticated
		
		UIDevice.current.isBatteryMonitoringEnabled	= true
        
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            PHPhotoLibrary.requestAuthorization({ auth in
                if auth != PHAuthorizationStatus.authorized {
                    self.log("App is not authorized to view photos. Please grant access.")
                }
            })
        }
	}
    
    func getWiFiAddress() -> String? {
        /// Gets the private IP of the host device
        
        var address : String?

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
    
	var bottom_bar: some View { /// just to break up the code
		HStack {
			HStack {
				HStack {
					HStack {
						Button(action: {
							self.loadFiles()
							self.s.launchMobileSMS()
						}) {
							Image(systemName: "goforward")
								.font(.system(size: self.font_size))
								.foregroundColor(Color.purple)
						}
				
						Spacer().frame(width: 24)
				
						Button(action: {
							(self.server_running && self.getWiFiAddress() != nil) ? self.stopServer() : nil
						}) {
							Image(systemName: "stop.fill")
								.font(.system(size: self.font_size))
								.foregroundColor(self.server_running ? Color.red : Color.gray)
						}
				
						Spacer().frame(width: 30)
				
						Button(action: {
							self.server_running || self.getWiFiAddress() == nil ? nil : self.loadServer(port_num: UInt16(self.port)!)
							UserDefaults.standard.setValue(true, forKey: "has_run")
						}) {
							Image(systemName: "play.fill")
								.font(.system(size: self.font_size))
								.foregroundColor(self.server_running ? Color.gray : Color.green)
						}
				
					}.padding(10)
				
					Spacer()
				
					HStack {
						Button(action: {
							self.view_settings.toggle()
						}) {
							Image(systemName: "gear")
								.font(.system(size: 24))
						}.sheet(isPresented: $view_settings) {
							SettingsView()
						}
					}.padding(10)
				}.padding(8)
				
			}.background(LinearGradient(gradient: Gradient(colors: [Color("BeginningBlur"), Color("EndBlur")]), startPoint: .topLeading, endPoint: .bottomTrailing))
			.cornerRadius(16)
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.stroke(Color(UIColor.tertiarySystemBackground), lineWidth: 2)
			)
			.shadow(radius: 7)
			
		}.padding(.init(top: 6, leading: 10, bottom: 6, trailing: 10))
		.frame(height: 80)
		.background(Color(UIColor.secondarySystemBackground))
	}
	
    var body: some View {
        
        let port_binding = Binding<String>(get: {
            self.port
        }, set: {
            let new_port = $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().count > 3 ?
                            $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined() :
                            UserDefaults.standard.object(forKey: "port") as? String ?? "8741" /// To make sure it's an available port
			self.port = new_port
			UserDefaults.standard.setValue(new_port, forKey: "port")
        })
        
        let pass_binding = Binding<String>(get: {
            self.password
        }, set: {
            self.password = $0
            UserDefaults.standard.setValue($0, forKey: "password")
        })
        
        return VStack {
            HStack {
                Text("SMServer")
                    .font(.largeTitle)
                
                Spacer()
            }.padding()
            .padding(.top, 14)
            
            if self.getWiFiAddress() != nil {
                Text("Visit http\(secure ? "s" : "")://\(self.getWiFiAddress() ?? "your phone's private IP, port "):\(port) in your browser to view your messages!")
                    .font(Font.custom("smallTitle", size: 22))
                    .padding()
            } else {
                Text("Please connect to wifi to operate the server.")
                    .font(Font.custom("smallTitle", size: 22))
                    .padding()
            }
            
            Spacer().frame(height: 20)
            
            HStack {
                Text("To learn more, visit")
                    .font(.headline)
                Text("the github repo")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        let url = URL.init(string: "https://github.com/iandwelker/smserver")
                        guard let github_url = url, UIApplication.shared.canOpenURL(github_url) else { return }
                        UIApplication.shared.open(github_url)
                    }
            }
            
            GeometryReader { geo in
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .padding(.init(top: geo.size.width * 0.2, leading: geo.size.width * 0.15, bottom: geo.size.width * 0.2, trailing: geo.size.width * 0.15))
                        .foregroundColor(Color(UIColor.tertiarySystemBackground))
                        .shadow(radius: 7)
                    
                    VStack {
                        HStack {
                            Text("Port")
                            
                            Spacer().frame(width: 10)
                            
                            TextField("Port number", text: port_binding)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disableAutocorrection(true)
                            
                        }.frame(width: geo.size.width * self.geo_width)
                        
                        HStack {
                            Text("Pass")
                            
                            Spacer().frame(width: 10)
                            
                            TextField("Password", text: pass_binding)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disableAutocorrection(true)
                        }.frame(width: geo.size.width * self.geo_width)
                        
                        Spacer().frame(height: 30)
                        
                        HStack {
                            
                            Button(action: {
                                let picker = DocPicker(
                                    supportedTypes: ["public.text"],
                                    onPick: { url in
                                        if self.debug {
                                            self.log("document chosen")
                                        }
                                        do {
                                            try FileManager.default.copyItem(at: url, to: self.custom_css_path)
                                        } catch {
                                            self.log("Couldn't move custom css")
                                        }
                                    }, onDismiss: {
                                        if self.debug {
                                            self.log("picker dismissed")
                                        }
                                    }
                                )
                                UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                            }) {
                                Text("Set custom CSS")
                                    .padding(8)
                                    .background(Color.blue)
                                    .cornerRadius(40)
                                    .foregroundColor(Color.white)
                            }
                            
                            Spacer().frame(width: 10)
                            
                            Button(action: {
                                do {
                                    try FileManager.default.removeItem(at: self.custom_css_path)
                                    if self.debug {
                                        self.log("Removed custom css file")
                                    }
                                } catch {
                                    self.log("Failed to remove custom css file")
                                }
                            }) {
                                Image(systemName: "trash")
                                    .padding(12)
                                    .background(Color.blue)
                                    .cornerRadius(40)
                                    .foregroundColor(Color.white)
                            }
                        }
                    }
                }
			}
            
            Spacer()
            
            if UserDefaults.standard.object(forKey: "has_run") == nil {
                HStack {
                    Text("Tap the arrow to start!")
                        .font(.callout)
                    Spacer()
                }.padding(.leading)
			} else {
				Spacer().frame(height: 20)
			}
            
            Spacer()
			
			bottom_bar /// created above
            
        }.onAppear() {
            self.loadFuncs()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

class DocPicker: UIDocumentPickerViewController, UIDocumentPickerDelegate {
    /// Document Picker
    
    private let onDismiss: () -> Void
    private let onPick: (URL) -> ()
    
    init(supportedTypes: [String], onPick: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onPick = onPick
        
        super.init(documentTypes: supportedTypes, in: .open)
        
        allowsMultipleSelection = false
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick(urls.first ?? URL(fileURLWithPath: ""))
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onDismiss()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

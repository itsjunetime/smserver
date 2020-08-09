import SwiftUI
import GCDWebServer
import Telegraph
import os

struct ContentView: View {
    let server = GCDWebUploader(uploadDirectory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.path)
	let socket = SocketDelegate()
    let prefix = "SMServer_app: "
    let geo_width: CGFloat = 0.6
    let font_size: CGFloat = 25
    
    @State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    @State var authenticated_addresses = UserDefaults.standard.object(forKey: "authenticated_addresses") as? Array<String> ?? [String]()
    @State var custom_css = UserDefaults.standard.object(forKey: "custom_css") as? String ?? ""
    @State var port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
    @State var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
	@State var socket_port: Int = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740
	@State var shown_phone_alert: Bool = UserDefaults.standard.object(forKey: "shown_phone_alert")  as? Bool ?? false
    @State var light_theme: Bool = UserDefaults.standard.object(forKey: "light_theme") as? Bool ?? false
	
    @State var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    @State var view_settings = false
    @State var server_running = false
    @State var alert_connected = false
    @State var has_root = false
    @State var show_picker = false
	@State var show_phone_alert = false
    
    static let chat_delegate = ChatDelegate()
    @State var s = Sender()
    @State var watcher: IPCTextWatcher = IPCTextWatcher.sharedInstance()
    
    let custom_css_path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("smserver_custom.css")
    
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
        os_log("%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, self.prefix, s)
    }
    
    func loadServer(port_num: UInt16) {
        /// This starts the server at port $port_num
        
        self.debug ? self.log("Loading server at port \(String(port_num))") : nil
		
		let num = UserDefaults.standard.object(forKey: "full_number") as? String ?? ""
		let country = UserDefaults.standard.object(forKey: "country_code") as? String ?? ""
		
		if country.count == 0 || num.count == 0 {
			self.show_phone_alert = true /// Make them put in their number first
			return
		}
        
        if server.isRunning {
            self.stopServer()
            self.debug ? self.log("Server was already running, stopped.") : nil
        }
        
        self.s.launchMobileSMS()
        
        if self.debug {
            self.log("launched mobilesms")
        }
        
        server.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { request in
            
            let ip = request.remoteAddressString
            
            if self.debug {
                self.log("GET main: " + ip)
            }
            
            if self.checkIfAuthenticated(ras: String(ip.prefix(upTo: ip.firstIndex(of: ":") ?? ip.endIndex))) {
                return GCDWebServerDataResponse(html: self.main_page)
            } else {
                return GCDWebServerDataResponse(html: self.gatekeeper_page)
            }
        })
        
        server.addHandler(forMethod: "GET", path: "/requests", request: GCDWebServerRequest.self, processBlock: { request in
            /// There is no authentication handler here 'cause it handles that within parseAndReturn()
            /// since they send the password auth request to this subdirectory
            
            let query = request.query
            
            if query != nil && query?.count == 0 {
                return GCDWebServerDataResponse(html: self.requests_page)
            } else {
                
                let address = String(request.remoteAddressString.prefix(upTo: request.remoteAddressString.firstIndex(of: ":")!))
                
                if self.debug {
                    self.log("GET /requests: \(address)")
                }
                
                let response = self.parseAndReturn(params: query ?? [String:String](), address: address)
                
                if self.debug {
                    self.log("Returning from /requests")
                }
                
                return GCDWebServerDataResponse(text: response)
            }
        })
		
		server.addHandler(forMethod: "GET", path: "/data", request: GCDWebServerRequest.self, processBlock: { request in
			let ip = request.remoteAddressString
   
			if self.debug {
				self.log("GET profile: " + ip)
			}
			
			if !self.checkIfAuthenticated(ras: String(ip.prefix(upTo: ip.firstIndex(of: ":") ?? ip.endIndex))) {
				return GCDWebServerDataResponse(text: "")
			}
			
			if self.debug {
				self.log("returning data")
			}
			
			let f = request.query?.keys.first
			
			if f == "chat_id" {
				return GCDWebServerDataResponse(data: ContentView.chat_delegate.returnImageData(chat_id: request.query?["chat_id"] ?? ""), contentType: "image/jpeg")
			} else if f == "path" {
				
				let dataResponse = ContentView.chat_delegate.getAttachmentDataFromPath(path: request.query?["path"] ?? "")
				let type = ContentView.chat_delegate.getAttachmentType(path: request.query?["path"] ?? "")
				
				return GCDWebServerDataResponse(data: dataResponse, contentType: type)
			} else if f == "photo" {
				return GCDWebServerDataResponse(data: ContentView.chat_delegate.getPhotoDatafromPath(path: request.query?["photo"] ?? ""), contentType: "image/png")
			}
			
			return GCDWebServerDataResponse(data: Data.init(capacity: 0), contentType: "") /// Nothing
		})
        
        server.addHandler(forMethod: "POST", path: "/send", request: GCDWebServerMultiPartFormRequest.self, processBlock: { request in
            let ip = request.remoteAddressString
            
            if self.debug {
                self.log("POST uploads: " + ip)
            }
            
            if !self.checkIfAuthenticated(ras: String(ip.prefix(upTo: ip.firstIndex(of: ":") ?? ip.endIndex))) {
                return GCDWebServerDataResponse(text: "")
            }
            
            let send = self.sendText(req: (request as! GCDWebServerMultiPartFormRequest))
            
            if self.debug {
                self.log("Returning from sending text")
            }
            
			return GCDWebServerDataResponse(text: send ? "true" : "false")
        })
        
        server.addHandler(forMethod: "GET", path: "/style.css", request: GCDWebServerRequest.self, processBlock: { request in
            let ip = request.remoteAddressString
            
            if self.debug {
                self.log("GET style.css: \(ip)")
            }
            
            if !self.checkIfAuthenticated(ras: String(ip.prefix(upTo: ip.firstIndex(of: ":") ?? ip.endIndex))) {
                return GCDWebServerDataResponse(text: "")
            }
            
            return GCDWebServerDataResponse(text: self.main_page_style)
        })
        
        server.addHandler(forMethod: "GET", path: "/custom.css", request: GCDWebServerRequest.self, processBlock: { request in
            let ip = request.remoteAddressString
            
            if self.debug {
                self.log("GET /custom.css: \(ip)")
            }
            
            if !self.checkIfAuthenticated(ras: String(ip.prefix(upTo: ip.firstIndex(of: ":") ?? ip.endIndex))) {
                return GCDWebServerDataResponse(text: "")
            }
            
            return GCDWebServerDataResponse(text: self.custom_style)
        })
        
        server.addHandler(forMethod: "GET", path: "/light.css", request: GCDWebServerRequest.self, processBlock: { request in
            let ip = request.remoteAddressString
            
            if self.debug {
                self.log("GET /light.css: \(ip)")
            }
            
            if !self.checkIfAuthenticated(ras: String(ip.prefix(upTo: ip.firstIndex(of: ":") ?? ip.endIndex))) {
                return GCDWebServerDataResponse(text: "")
            }
            
            return GCDWebServerDataResponse(text: self.light_style)
        })
        
        server.addHandler(forMethod: "GET", path: "/favicon.ico", request: GCDWebServerRequest.self, processBlock: { request in
            let photo = UIImage(named: "icon")
            let data = photo?.pngData()            
            return GCDWebServerDataResponse(data: data ?? Data.init(capacity: 0), contentType: "image/png")
        })
        
        if self.debug {
            self.log("Got past adding all the handlers.")
        }
        
        do {
            let port = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
            try server.start(options: ["Port": UInt(port) ?? UInt(8741), "BonjourName": "GCD Web Server", "AutomaticallySuspendInBackground": false])
        } catch {
            self.log("failed to start server. Try again or try reinstalling.")
        }
		
		socket.startServer(port: self.socket_port)
		
        self.server_running = server.isRunning
        
        if self.debug {
            self.log("Successfully started server and launched MobileSMS")
        }
    }
    
    func sendText(req: GCDWebServerMultiPartFormRequest) -> Bool {
        
        var body = ""
        var address = ""
        var files = [String]()
        
        for i in Array(req.arguments) {
            if (i.string?.prefix(5) == "text:") {
				body = String(i.string?.suffix(i.string!.count - 5) ?? "")
            } else if (i.string?.prefix(5) == "chat:") {
				address = String(i.string?.suffix(i.string!.count - 5) ?? "")
            }
        }
        
        let fm = FileManager.default
        
        for i in req.files {
            do {
                let attr = try fm.attributesOfItem(atPath: i.temporaryPath)
                let fileSize = attr[FileAttributeKey.size] as! UInt64
                
                if fileSize == 0 {
                    continue
                }
            } catch {
                self.log("couldn't get filesize")
            }
            
            let newFilePath = String(i.temporaryPath.prefix(upTo: i.temporaryPath.lastIndex(of: "/") ?? i.temporaryPath.endIndex) + "/" + i.fileName).replacingOccurrences(of: " ", with: "_") /// I don't like spaces in file names. Also could cause bad behavior (I think?)
            
            if fm.fileExists(atPath: newFilePath) {
                do {
                    try fm.removeItem(atPath: newFilePath)
                } catch {
                    self.log("Couldn't remove file from path: \(newFilePath), for whatever reason")
                }
            }
            do {
                try FileManager.default.moveItem(at: URL(fileURLWithPath: i.temporaryPath), to: URL(fileURLWithPath: newFilePath))
            } catch {
                self.log("failed to move file; won't send text")
                return false
            }
            
            files.append(newFilePath)
        }
		
		if !(address.contains("@") || address.prefix(1) == "+" || address.prefix(4) == "chat") {
			/// This is the only area where your phone number is actually used
			/// It checks the phone number that the text is being sent to and adds the '+'/country code/area code onto it if they are not included
			
			let full_number: String = UserDefaults.standard.object(forKey: "full_number") as? String ?? ""
			let area_code: String = UserDefaults.standard.object(forKey: "area_code") as? String ?? "" /// NYC?
			let country_code: String = UserDefaults.standard.object(forKey: "country_code") as? String ?? "" /// US
			
			address = address.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
			
			if !(address.count < full_number.count) {
				if address.count == full_number.count {
					address = "+" + country_code + area_code + address
				} else if address.count == (area_code + full_number).count {
					address = "+" + country_code + address
				} else if address.count == (country_code + area_code + full_number).count {
					address = "+" + address
				}
			}
		} else if address.prefix(1) == "+" { /// Make sure there are no unnecessary characters like parenthesis
			address = "+" + address.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
		}
        
        if !(body == "" && files.count == 0) {
            self.s.sendIPCText(body, toAddress: address, withAttachments: files)
			//self.setNewestTexts(address)
			
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
        
        let default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 60
        let default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 200
        
        self.light_theme = UserDefaults.standard.object(forKey: "light_theme") as? Bool ?? false
        
        if let h = Bundle.main.url(forResource: "chats", withExtension: "html", subdirectory: "html"),
        let s = Bundle.main.url(forResource: "style", withExtension: "css", subdirectory: "html"),
        let g = Bundle.main.url(forResource: "gatekeeper", withExtension: "html", subdirectory: "html"),
        let l = Bundle.main.url(forResource: "light_theme", withExtension: "css", subdirectory: "html") {
            do {
                self.main_page = try String(contentsOf: h, encoding: .utf8)
                    .replacingOccurrences(of: "var num_texts_to_load;", with: "var num_texts_to_load = \(default_num_messages);")
                    .replacingOccurrences(of: "var num_chats_to_load;", with: "var num_chats_to_load = \(default_num_chats);")
					.replacingOccurrences(of: "var socket_port;", with: "var socket_port = \(String(socket_port));")
                    .replacingOccurrences(of: "<!--light-->", with: self.light_theme ? "<link rel=\"stylesheet\" type=\"text/css\" href=\"light.css\">" : "")
					
                self.main_page_style = try String(contentsOf: s, encoding: .utf8)
                self.gatekeeper_page = try String(contentsOf: g, encoding: .utf8)
                self.light_style = try String(contentsOf: l, encoding: .utf8)
            } catch {
                self.log("WARNING: ran into an error with loading the files, try again.")
            }
        }
        
        do {
            self.custom_style = try String(contentsOf: self.custom_css_path, encoding: .utf8)
        } catch {
            self.log("Could not load custom css file")
            self.custom_style = ""
        }
        
        self.debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    }
    
    func checkIfConnected() -> Bool {
        return ContentView.chat_delegate.checkIfConnected()
    }
    
    func setNewestTexts(_ chat_id: String) -> Void {
        ContentView.chat_delegate.setNewTexts(chat_id)
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
            print("parsing:")
            print(params)
            if self.debug {
                for i in Array(params.keys) {
                    self.log("parsing \(i) and \(String(describing: params[i]))")
                }
            }
        }
        
        let password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
        
        if Array(params.keys)[0] == "password" {
            if self.debug {
                self.log("comparing " + Array(params.values)[0] + " to " + password)
            }
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
            } else {
                return "false"
            }
        }
        
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
			
            let texts_array = ContentView.chat_delegate.loadMessages(num: person, num_items: num_texts, offset: offset)
            let texts = encodeToJson(object: texts_array, title: "texts")
            return texts
            
        } else if f == "chat" || f == "num_chats"  || f == "chats_offset" {
            
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
            DispatchQueue.main.async {
                ContentView.chat_delegate.setFirstTexts(address: address);
            }
            return chats
            
        } else if f == "name" {
            
            chat_id = params["name"] ?? ""
            
            let name = ContentView.chat_delegate.getDisplayName(chat_id: chat_id)
            return name
            
        } else if f == "check" {
            
            let lt = encodeToJson(object: ContentView.chat_delegate.newest_texts, title: "chat_ids")
            ContentView.chat_delegate.newest_texts = [String]()
            if self.debug  {
                print("lt:")
                print(lt)
            }
            return lt
            
		} else if f == "search" || f == "case_sensitive" || f == "bridge_gaps" {
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
		} else {
            self.debug ? print("We haven't implemented this functionality yet, sorry :/") : nil
        }
        
        return ""
    }
    
    func stopServer() {
        /// Stops the server & and de-authenticates all ip addresses
        
        self.server.stop()
		socket.stopServer()
        if self.debug {
            self.log("Stopped Server")
        }
        self.authenticated_addresses = [String]()
        server_running = server.isRunning
    }
	
	func loadFuncs() {
		/// All the functions that run on scene load
		
		self.loadFiles()
		(UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false && !self.server.isRunning) ? self.loadServer(port_num: UInt16(self.port) ?? UInt16(8741)) : nil
		
		self.has_root = self.s.setUID() == uid_t(0)
		//self.show_root_alert = self.debug
		self.watcher.setTexts = { value in
			self.setNewestTexts(value ?? "None")
		}
		
		socket.watcher = self.watcher
		socket.authenticated_addresses = self.authenticated_addresses
		socket.verify_auth = self.checkIfAuthenticated
		
		UIDevice.current.isBatteryMonitoringEnabled	= true
		
		show_phone_alert = !shown_phone_alert
		UserDefaults.standard.setValue(true, forKey: "shown_phone_alert")
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
							self.alert_connected = self.debug
							self.s.launchMobileSMS()
						}) {
							Image(systemName: "goforward")
								.font(.system(size: self.font_size))
								.foregroundColor(Color.purple)
						}.alert(isPresented: $alert_connected, content: {
							Alert(title: Text("Checking connection to sms.db"),
									message: Text( self.checkIfConnected() ? "You can connect to the database." :
									"You cannot connect to the database; you are still sandboxed. This will prevent the app from working at all. Contact the developer about this issue."
							))
						})
				
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
			self.port = $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().count > 4 ?
						$0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined() :
						UserDefaults.standard.object(forKey: "port") as? String ?? "8741" /// To make sure it's an available port
			UserDefaults.standard.setValue(self.port, forKey: "port")
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
                Text("Visit \(self.getWiFiAddress() ?? "your phone's private IP, port "):\(port) in your browser to view your messages!")
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
		.alert(isPresented: $show_phone_alert, content: {
			Alert(title: Text("To finish setup"), message: Text("Please enter your phone number in the settings section of this app. This is necessary to add your country/area code onto new conversations if they don't include it."))
		})
        .background(Color(UIColor.secondarySystemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

class DocPicker: UIDocumentPickerViewController, UIDocumentPickerDelegate {
    
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

//
//  ContentView.swift
//  SMServer
//
//  Created by Ian Welker on 4/30/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

import SwiftUI
import GCDWebServer
import SQLite3
import MessageUI

struct ContentView: View {
    let server = GCDWebServer()
    let bbheight: CGFloat? = 40
    let bbsize: CGSize = CGSize(width: 1.8, height: 1.8)
    let prefix = "SMServer: "
    
    @State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    
    @State var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    @State var view_settings = false
    @State var server_running = false
    @State var authenticated_addresses = [String]()
    @State var alert_connected = false
    
    let chat_delegate = ChatDelegate()
    let s = sender()
    
    let messagesString = "/private/var/mobile/Library/SMS/sms.db"
    let messagesURL = URL(fileURLWithPath: "/private/var/mobile/Library/SMS/sms.db")
    static let imageStoragePrefix = "/private/var/mobile/Library/SMS/Attachments/"
    static let userHomeString = "/private/var/mobile/"
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
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
    
    func loadServer(port_num: UInt16) {
        /// This starts the server at port $port_num
        
        server.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { request in
            if self.debug {
                print("headers:")
                print(request.headers)
                print("query:")
                print(request.query as Any)
                print("url:")
                print(request.url)
                print("ras:")
                print(request.remoteAddressString)
            }
            
            self.debug ? print(prefix + "entered default handler") : nil
            
            if self.checkIfAuthenticated(ras: String(request.remoteAddressString.prefix(upTo: request.remoteAddressString.firstIndex(of: ":")!))) {
                return GCDWebServerDataResponse(html: self.main_page)
            } else {
                return GCDWebServerDataResponse(html: self.gatekeeper_page)
            }
        })
        
        server.addHandler(forMethod: "GET", path: "/requests", request: GCDWebServerRequest.self, processBlock: { request in
            if self.debug {
                print("headers:")
                print(request.headers)
                print("query:")
                print(request.query as Any)
                print("url:")
                print(request.url)
                print("ras:")
                print(request.remoteAddressString)
            }
            
            let query = request.query
            
            if query != nil && query?.count == 0 {
                return GCDWebServerDataResponse(html: self.requests_page)
            } else {
                
                let address = String(request.remoteAddressString.prefix(upTo: request.remoteAddressString.firstIndex(of: ":")!))
                
                let response = self.parseAndReturn(params: query ?? [String:String](), address: address)
                
                return GCDWebServerDataResponse(text: response)
            }
        })
        
        server.addHandler(forMethod: "GET", path: "/attachments", request: GCDWebServerRequest.self, processBlock: { request in
            
            if !self.checkIfAuthenticated(ras: String(request.remoteAddressString.prefix(upTo: request.remoteAddressString.firstIndex(of: ":")!))) {
                return GCDWebServerDataResponse(text: "")
            }
            
            let dataResponse = chat_delegate.getAttachmentDataFromPath(path: request.query?["path"] ?? "")
            let type = chat_delegate.getAttachmentType(path: request.query?["path"] ?? "")
            
            return GCDWebServerDataResponse(data: dataResponse, contentType: type)
        })
        
        server.addHandler(forMethod: "GET", path: "/profile", request: GCDWebServerRequest.self, processBlock: { request in
            
            if !self.checkIfAuthenticated(ras: String(request.remoteAddressString.prefix(upTo: request.remoteAddressString.firstIndex(of: ":")!))) {
                return GCDWebServerDataResponse(text: "")
            }
            
            return GCDWebServerDataResponse(data: chat_delegate.returnImageData(chat_id: request.query?["chat_id"] ?? ""), contentType: "image/jpeg")
        })
        
        server.addHandler(forMethod: "GET", path: "/style.css", request: GCDWebServerRequest.self, processBlock: { request in
            
            if !self.checkIfAuthenticated(ras: String(request.remoteAddressString.prefix(upTo: request.remoteAddressString.firstIndex(of: ":")!))) {
                return GCDWebServerDataResponse(text: "")
            }
            
            return GCDWebServerDataResponse(text: self.main_page_style)
        })
        
        do {
            let port = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
            try server.start(options: ["Port": UInt(port) ?? UInt(8741), "BonjourName": "GCD Web Server", "AutomaticallySuspendInBackground": false])
        } catch {
            print(prefix + "failed to start server. fat rip right there.")
        }
        self.server_running = server.isRunning
        
        self.startBackgroundTask()
    }
    
    func startBackgroundTask() {
        /// This starts the background task... I may deprecate this soon and put it in like SceneDelegate or AppDelegate
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            //self.stopServer()
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        })
        
        assert(backgroundTask != .invalid)
    }
    
    func loadFiles() {
        /// This sets the website page files to local variables
        
        let default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 100
        let default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 40
        let server_ping = UserDefaults.standard.object(forKey: "server_ping") as? Int ?? 60
        
        if let h = Bundle.main.url(forResource: "chats", withExtension: "html", subdirectory: "html"),
        let c = Bundle.main.url(forResource: "style", withExtension: "css", subdirectory: "html"),
        let g = Bundle.main.url(forResource: "gatekeeper", withExtension: "html", subdirectory: "html") {
            do {
                self.main_page = try String(contentsOf: h, encoding: .utf8)
                    .replacingOccurrences(of: "const num_texts_to_load;", with: "const num_texts_to_load = \(default_num_messages);")
                    .replacingOccurrences(of: "const num_chats_to_load;", with: "const num_chats_to_load = \(default_num_chats);")
                    .replacingOccurrences(of: "const timeout;", with: "const timeout = \(server_ping)000;")
                self.main_page_style = try String(contentsOf: c, encoding: .utf8)
                self.gatekeeper_page = try String(contentsOf: g, encoding: .utf8)
            }
            catch {
                print(prefix + "WARNING: ran into an error with loading the files, try again.")
            }
        }
    }
    
    func checkIfConnected() -> Bool {
        return chat_delegate.checkIfConnected()
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
            print(prefix + "parsing:")
            print(params)
        }
        
        let password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
        
        if Array(params.keys)[0] == "password" {
            self.debug ? print(prefix + "comparing " + Array(params.values)[0] + " to " + password) : nil
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
        
        var person = ""
        var num_texts = 0
        var offset = 0
        
        var chat_id = ""
        
        var sendBody = ""
        var sendAddress = ""
        
        let f = Array(params.keys)[0]
        var s = ""
        if params.count > 1 {
            s = Array(params.keys)[1]
        }
        var t = ""
        if params.count > 2 {
            t = Array(params.keys)[2]
        }
        if f == "person" || f == "num" || f == "offset" {
            
            person = f == "person" ? Array(params.values)[0] : (s == "person" ? Array(params.values)[1] : Array(params.values)[2])
            
            num_texts = default_num_messages
            if f == "num" || s == "num" || t == "num" {
                num_texts = (f == "num" ? Int(Array(params.values)[0]) : (s == "num" ? Int(Array(params.values)[1]) : Int(Array(params.values)[2]))) ?? default_num_chats
            }
            if f == "offset" || s == "offset" || t == "offset" {
                offset = (f == "offset" ? Int(Array(params.values)[0]) : (s == "offset" ? Int(Array(params.values)[1]) : Int(Array(params.values)[2]))) ?? 0
            }
            
            self.debug ? print(prefix + "selecting person: " + person + ", num: " + String(num_texts)) : nil
            
            if person.contains("\"") { /// Just in case, I guess?
                person = person.replacingOccurrences(of: "\"", with: "")
            }
            let texts_array = chat_delegate.loadMessages(num: person, num_items: num_texts, offset: offset)
            let texts = encodeToJson(object: texts_array, title: "texts")
            return texts
            
        } else if f == "chat" || f == "num_chats"  || f == "chats_offset" {
            
            num_texts = default_num_chats
            var chats_offset = 0
            if f == "num_chats" || s == "num_chats" || t == "num_chats" {
                num_texts = (f == "num_chats" ? Int(Array(params.values)[0]) : (s == "num_chats" ? Int(Array(params.values)[1]) : Int(Array(params.values)[2]))) ?? default_num_chats
            }
            if f == "chats_offset" || s == "chats_offset" || t == "chats_offset" {
                chats_offset = (f == "chats_offset" ? Int(Array(params.values)[0]) : (s == "chats_offset" ? Int(Array(params.values)[1]) : Int(Array(params.values)[2]))) ?? 0
            }
            
            if self.debug {
                print(prefix + "num chats: \(num_texts)")
                print(prefix + "chats offset: \(chats_offset)")
            }
            
            let chats_array = chat_delegate.loadChats(num_to_load: num_texts, offset: chats_offset)
            let chats = encodeToJson(object: chats_array, title: "chats")
            DispatchQueue.main.async {
                chat_delegate.setFirstTexts(address: address);
            }
            return chats
            
        } else if f == "name" {
            
            chat_id = Array(params.values)[0]
            
            let name = chat_delegate.getDisplayName(chat_id: chat_id)
            return name
            
        } else if f == "send" || f == "to" {
            
            sendBody = f == "send" ?  Array(params.values)[0] : Array(params.values)[1]
            sendAddress = s == "to" ? Array(params.values)[1] : Array(params.values)[0]
            sendText(body: sendBody, address: [sendAddress])
            
        } else if f == "check" {
            
            let lt = encodeToJson(object: chat_delegate.checkLatestTexts(address: address), title: "chat_ids")
            if self.debug  {
                print(prefix + "lt:")
                print(lt)
            }
            return lt
            
        } else if f == "log" {
            return chat_delegate.printLog()
        } else {
            self.debug ? print(prefix + "We haven't implemented this functionality yet, sorry :/") : nil
        }
        
        return ""
    }
    
    func stopServer() {
        /// Stops the server & and de-authenticates all ip addresses
        
        self.server.stop()
        self.debug ? print(prefix + "Stopped server") : nil
        self.authenticated_addresses = [String]()
        server_running = server.isRunning
    }
    
    func sendText(body: String, address: [String]) {
        /// Sends a text with the body of $body and to the address $address[0]. Don't quite know why address is an array; need to fix that.
        
        self.debug ? print(prefix + "body: \(body), address[0]: \(address[0])") : nil
        
        s.sendIPCText(body, toAddress: address[0])
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
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

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
    
    var body: some View {
        let port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
        
        return NavigationView {
                VStack {
                    Text("Visit \(self.getWiFiAddress() ?? "your phone's private IP, port "):\(port) in your browser to view your messages!")
                        .font(Font.custom("smallTitle", size: 22))
                        .padding()
                    
                    Spacer().frame(height: 20)
                    
                    HStack {
                        Text("To learn more, visit")
                            .font(.headline)
                        Text("the github repo")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                let url = URL.init(string: "https://github.com/iandwelker/smserver.git")
                                guard let github_url = url, UIApplication.shared.canOpenURL(github_url) else { return }
                                UIApplication.shared.open(github_url)
                            }
                    }
                    
                    Spacer()
                    
                    if UserDefaults.standard.object(forKey: "has_run") == nil {
                        HStack {
                            Text("Tap the arrow to start!")
                                .font(.callout)
                            Spacer()
                        }.padding(.leading)
                    }
                    
                    HStack {
                        HStack {
                            Button(action: {
                                self.loadFiles()
                                //s.sendIPCAttachment("attachment test", toAddress: "+15202621123", withAttachment: "/var/mobile/media/DCIM/100APPLE/IMG_0584.JPG") ///TESTING
                                self.alert_connected = true
                                chat_delegate.printLog()
                            }) {
                                Image(systemName: "goforward")
                                    .scaleEffect(1.5)
                                    .foregroundColor(Color.purple)
                            }.alert(isPresented: $alert_connected, content: {
                                    Alert(title: Text("Checking connection to sms.db"),
                                            message: Text( self.checkIfConnected() ? "You can connect to the database." :
                                            "You cannot connect to the database; you are still sandboxed. This will prevent the app from working at all. Contact the developer about this issue."
                                    ))
                            })
                            
                            Spacer().frame(width: 30)
                            
                            Button(action: {
                                self.server_running ? self.stopServer() : nil
                            }) {
                                Image(systemName: "stop.fill")
                                    .scaleEffect(1.5)
                                    .foregroundColor(self.server_running ? Color.red : Color.gray)
                            }
                            
                            Spacer().frame(width: 30)
                            
                            Button(action: {
                                self.server_running ? nil : self.loadServer(port_num: UInt16(port)!)
                                UserDefaults.standard.setValue(true, forKey: "has_run")
                            }) {
                                Image(systemName: "play.fill")
                                    .scaleEffect(1.5)
                                    .foregroundColor(self.server_running ? Color.gray : Color.green)
                            }
                            
                        }.padding(10)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                self.view_settings.toggle()
                            }) {
                                Image(systemName: "gear")
                                    .scaleEffect(1.5)
                            }.sheet(isPresented: $view_settings) {
                                SettingsView()
                            }
                        }.padding(10)
                    }
                    .padding()
                    
                }.navigationBarTitle(Text("SMServer").font(.largeTitle))
            
        }
        .onAppear() {
            self.loadFiles()
            UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false ? self.loadServer(port_num: UInt16(port) ?? UInt16(8741)) : nil
            s.launchMobileSMS()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

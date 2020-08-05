import SwiftUI

struct SettingsView: View {
    @State var port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
    @State var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
    
    @State var default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 60
    @State var default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 200
	@State var default_num_photos = UserDefaults.standard.object(forKey: "num_photos") as? Int ?? 40
    @State var server_ping = UserDefaults.standard.object(forKey: "server_ping") as? Int ?? 10
	@State var socket_port = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740
    
    @State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    @State var start_on_load: Bool = UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false
    @State var require_authentication: Bool = UserDefaults.standard.object(forKey: "require_auth") as? Bool ?? true
    @State var background: Bool = UserDefaults.standard.object(forKey: "enable_backgrounding") as? Bool ?? true
	
	@State var full_number: String = UserDefaults.standard.object(forKey: "full_number") as? String ?? ""
	@State var area_code: String = UserDefaults.standard.object(forKey: "area_code") as? String ?? ""
	@State var country_code: String = UserDefaults.standard.object(forKey: "country_code") as? String ?? ""
	
	@ObservedObject private var keyWatcher = KeyboardWatcher()
	
	func resetDefaults() {
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
	}
    
    var body: some View {
        
        let chats_binding = Binding<Int>(get: {
            self.default_num_chats
        }, set: {
            self.default_num_chats = Int($0)
            UserDefaults.standard.setValue(Int($0), forKey: "num_chats")
        })
        
        let messages_binding = Binding<Int>(get: {
            self.default_num_messages
        }, set: {
            self.default_num_messages = Int($0)
            UserDefaults.standard.setValue(Int($0), forKey: "num_messages")
        })
		
		let photos_binding = Binding<Int>(get: {
			self.default_num_photos
		}, set: {
			self.default_num_photos = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "num_photos")
		})
        
        let ping_binding = Binding<Int>(get: {
            self.server_ping
        }, set: {
            self.server_ping = Int($0)
            UserDefaults.standard.setValue(Int($0), forKey: "server_ping")
        })
        
        let debug_binding = Binding<Bool>(get: {
            self.debug
        }, set: {
            self.debug = $0
            UserDefaults.standard.setValue($0, forKey: "debug")
        })
        
        let start_binding = Binding<Bool>(get: {
            self.start_on_load
        }, set: {
            self.start_on_load = $0
            UserDefaults.standard.setValue($0, forKey: "start_on_load")
        })
        
        let auth_binding = Binding<Bool>(get: {
            self.require_authentication
        }, set: {
            self.require_authentication = $0
            UserDefaults.standard.setValue($0, forKey: "require_auth")
        })
        
        let background_binding = Binding<Bool>(get: {
            self.background
        }, set: {
            self.background = $0
            UserDefaults.standard.setValue($0, forKey: "enable_backgrounding")
        })
		
		let socket_binding = Binding<Int>(get: {
			self.socket_port
		}, set: {
			self.socket_port = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "socket_port")
		})
		
		let country_binding = Binding<String>(get: {
			self.country_code
		}, set: {
			self.country_code = $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
			UserDefaults.standard.setValue(self.country_code, forKey: "country_code")
		})
		
		let area_binding = Binding<String>(get: {
			self.area_code
		}, set: {
			self.area_code = $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
			UserDefaults.standard.setValue(self.area_code, forKey: "area_code")
		})
		
		let number_binding = Binding<String>(get: {
			self.full_number
		}, set: {
			self.full_number = $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
			UserDefaults.standard.setValue(self.full_number, forKey: "full_number")
		})
        
		return ScrollView {
			VStack(spacing: 16) {
				HStack {
					Text("Settings")
						.font(.largeTitle)
					Spacer()
				}
				
				Spacer().frame(height: 12)
				
				Section {
				
					HStack {
						Text("Initial number of chats to load")
						Spacer()
						TextField("Chats", value: chats_binding, formatter: NumberFormatter())
							.textFieldStyle(RoundedBorderTextFieldStyle())
							.frame(width: 60)
					}
					
					HStack {
						Text("Initial number of messages to load")
						Spacer()
						TextField("Messages", value: messages_binding, formatter: NumberFormatter())
							.textFieldStyle(RoundedBorderTextFieldStyle())
							.frame(width: 60)
					}
					
					HStack {
						Text("Initial number of photos to load")
						Spacer()
						TextField("Photos", value: photos_binding, formatter: NumberFormatter())
							.textFieldStyle(RoundedBorderTextFieldStyle())
							.frame(width: 60)
					}
					
					HStack {
						Text("Interval for website to ping app (seconds)")
						Spacer()
						TextField("Ping", value: ping_binding, formatter: NumberFormatter())
							.textFieldStyle(RoundedBorderTextFieldStyle())
							.frame(width: 60)
					}
					
					HStack {
						Text("Websocket port")
						Spacer()
						TextField("Port", value: socket_binding, formatter: NumberFormatter())
							.textFieldStyle(RoundedBorderTextFieldStyle())
							.frame(width: 60)
					}
				}
				
				Spacer().frame(height: 20)
				
				Section {
				
					Toggle("Toggle debug", isOn: debug_binding)
				
					Toggle("Start server on load", isOn: start_binding)
				
					Toggle("Require Authentication to view messages", isOn: auth_binding)
					
					Toggle("Enable backgrounding", isOn: background_binding)
				}
				
				Section {
					Spacer().frame(height: 20)
					
					HStack {
						Text("Phone number (e.g. '1 394 283948')")
						Spacer()
					}
					
					GeometryReader { geo in
						HStack {
							TextField("Country code", text: country_binding)
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(width: geo.size.width * 0.3)
							
							TextField("Area code", text: area_binding)
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(width: geo.size.width * 0.3)
							
							TextField("Number", text: number_binding)
								.textFieldStyle(RoundedBorderTextFieldStyle())
						}
					}
					
					Spacer().frame(height: 30)
					
					Button(action: {
						self.resetDefaults()
					}) {
						Text("Reset Defaults")
							.padding(.init(top: 8, leading: 24, bottom: 8, trailing: 24))
							.background(Color.blue)
							.cornerRadius(8)
							.foregroundColor(Color.white)
					}
				}
				
				Spacer()
				
			}.padding()
			.offset(y: -1 * keyWatcher.currentHeight)
			.animation(.easeOut(duration: 0.16))
		}
    }
}

final class KeyboardWatcher : ObservableObject {
	private var notificationCenter = NotificationCenter.default
	@Published private(set) var currentHeight: CGFloat = 0
	
	init() {
		notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	deinit {
		notificationCenter.removeObserver(self)
	}

	@objc func keyBoardWillShow(notification: Notification) {
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			currentHeight = keyboardSize.height
		}
	}

	@objc func keyBoardWillHide(notification: Notification) {
		currentHeight = 0
	}
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

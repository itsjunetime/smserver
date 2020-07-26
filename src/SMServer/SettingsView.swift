//
//  SettingsView.swift
//  SMServer
//
//  Created by Ian Welker on 7/4/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @State var port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
    @State var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
    
    @State var default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 60
    @State var default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 200
    @State var server_ping = UserDefaults.standard.object(forKey: "server_ping") as? Int ?? 10
	@State var socket_port = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740
    
    @State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    @State var start_on_load: Bool = UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false
    @State var require_authentication: Bool = UserDefaults.standard.object(forKey: "require_auth") as? Bool ?? true
    @State var background: Bool = UserDefaults.standard.object(forKey: "enable_backgrounding") as? Bool ?? true
	
	@State var enable_sockets: Bool = UserDefaults.standard.object(forKey: "enable_sockets") as? Bool ?? true
	@State var enable_polling: Bool = UserDefaults.standard.object(forKey: "enable_polling") as? Bool ?? true
	@State var picker_select: Int = 2
	let picker_options = ["WebSockets" , "Long polling", "Both"]
	
	func setPicker() {
		if enable_sockets && enable_polling {
			picker_select = 2
		} else {
			picker_select = (enable_sockets ? 0 : 1) /// Do 1 if only enable_polling
		}
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
        
        return VStack(spacing: 16) {
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
			
			/*Spacer().frame(height: 20) /// This will be included later but is now failing to compile

			VStack(alignment: .leading, spacing: 0) {
				Text("How to detect new texts")
				
				Picker("Method", selection: $picker_select) {
					ForEach(0..<picker_options.count, id: \.self) { index in
						Text(self.picker_options[index]).tag(index)
					}
				}.pickerStyle(SegmentedPickerStyle())
			}*/
            
            Spacer()
            
        }.padding()
		.onAppear() {
			self.setPicker()
		}
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

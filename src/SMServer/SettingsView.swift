//
//  SettingsView.swift
//  SMServer
//
//  Created by Ian Welker on 7/4/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @State var default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 40
    @State var default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 100
    @State var server_ping = UserDefaults.standard.object(forKey: "server_ping") as? Int ?? 60
    
    @State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    @State var start_on_load: Bool = UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false
    
    @State var port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
    @State var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
    @State var require_authentication: Bool = UserDefaults.standard.object(forKey: "require_auth") as? Bool ?? true
    
    var body: some View {
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
        
        let pass_binding = Binding<String>(get: {
            self.password
        }, set: {
            self.password = $0
            UserDefaults.standard.setValue($0, forKey: "password")
        })
        
        let port_binding = Binding<String>(get: {
            self.port
        }, set: {
            self.port = $0
            UserDefaults.standard.setValue($0, forKey: "port")
        })
        
        let chats_binding = Binding<Int>(get: {
            self.default_num_chats
        }, set: {
            self.default_num_chats = $0
            UserDefaults.standard.setValue($0, forKey: "num_chats")
        })
        
        let messages_binding = Binding<Int>(get: {
            self.default_num_messages
        }, set: {
            self.default_num_messages = $0
            UserDefaults.standard.setValue($0, forKey: "num_messages")
        })
        
        let auth_binding = Binding<Bool>(get: {
            self.require_authentication
        }, set: {
            self.require_authentication = $0
            UserDefaults.standard.setValue($0, forKey: "require_auth")
        })
        
        let ping_binding = Binding<Int>(get: {
            self.server_ping
        }, set: {
            self.server_ping = $0
            UserDefaults.standard.setValue($0, forKey: "server_ping")
        })
        
        return VStack(spacing: 20) {
            HStack {
                Text("Settings").font(.title)
                Spacer()
            }
            
            HStack {
                Text("Change default port").font(.subheadline)
                Spacer()
            }
            
            TextField("Change default server port", text: port_binding)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            HStack {
                Text("Change password").font(.subheadline)
                Spacer()
            }
            
            TextField("Change requests password", text: pass_binding)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Text("Initial number of chats to load")
                Spacer()
                TextField("Chats", value: chats_binding, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }
            
            HStack {
                Text("Initial number of messages to load")
                Spacer()
                TextField("Messages", value: messages_binding, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }
            
            HStack {
                Text("Interval for website to ping app (seconds)")
                Spacer()
                TextField("Ping", value: ping_binding, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }
            
            Group {
            
                Toggle("Toggle debug", isOn: debug_binding)
            
                Toggle("Start server on load", isOn: start_binding)
            
                Toggle("Require Authentication to view messages", isOn: auth_binding)
            
                Spacer()
            }
        }.padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

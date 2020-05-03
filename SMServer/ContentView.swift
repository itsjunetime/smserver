//
//  ContentView.swift
//  SMServer
//
//  Created by Ian Welker on 4/30/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

import SwiftUI
import Swifter
import SQLite3

struct ContentView: View {
    let server = HttpServer()
    @State var test_messages: [[String]] = [[]]
    @State var messages_have_been_loaded = false
    @State var egnum = ""
    let messagesURL = URL(fileURLWithPath: "/private/var/mobile/Library/SMS/sms.db")
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    enum dbprop_types {
        case int
        case text
        case null
        case blob
    }
    
    class dbprop {
        init(data: String, type: dbprop_types, num: Int) {
            self.data = data
            self.type = type
            self.num = num
        }
        var data: String
        var type: dbprop_types //will be an enum
        var num: Int
    }
    
    class chat_dbprops {
        var ROWID = dbprop(data: "ROWID", type: dbprop_types.int, num: 0)
        var guid = dbprop(data: "guid", type: dbprop_types.text, num: 1)
        var style = dbprop(data: "style", type: dbprop_types.int, num: 2)
        var state = dbprop(data: "state", type: dbprop_types.int, num: 3)
        var account_id = dbprop(data: "account_id", type: dbprop_types.text, num: 4)
        var properties = dbprop(data: "properties", type: dbprop_types.blob, num: 5)
        var chat_identifier = dbprop(data: "chat_identifier", type: dbprop_types.text, num: 6)
        var service_name = dbprop(data: "service_name", type: dbprop_types.text, num: 7)
        var room_name = dbprop(data: "room_name", type: dbprop_types.text, num: 8)
        var account_login = dbprop(data: "account_login", type: dbprop_types.text, num: 9)
        var is_archived = dbprop(data: "is_archived", type: dbprop_types.int, num: 10)
        var last_addressed_handle = dbprop(data: "last_addressed_handle", type: dbprop_types.text, num: 11)
        var display_name = dbprop(data: "display_name", type: dbprop_types.text, num: 12)
        var group_id = dbprop(data: "group_id", type: dbprop_types.text, num: 13)
        var is_filtered = dbprop(data: "is_filtered", type: dbprop_types.int, num: 14)
        var successful_query = dbprop(data: "successful_query", type: dbprop_types.int, num: 15)
        var engram_id = dbprop(data: "engram_id", type: dbprop_types.null, num: 16)
        var server_change_token = dbprop(data: "server_change_token", type: dbprop_types.text, num: 17)
        var ck_sync_state = dbprop(data: "ck_sync_state", type: dbprop_types.int, num: 18)
        var last_read_message_timestamp = dbprop(data: "last_read_message_timestamp", type: dbprop_types.int, num: 19)
        var ck_record_system_property_blob = dbprop(data: "ck_record_system_property_blob", type: dbprop_types.null, num: 20)
        var original_group_id = dbprop(data: "original_group_id", type: dbprop_types.text, num: 21)
        var sr_server_change_token = dbprop(data: "sr_server_change_token", type: dbprop_types.null, num: 22)
        var sr_ck_sync_state = dbprop(data: "sr_ck_sync_state", type: dbprop_types.int, num: 23)
        var sr_ck_record_system_property_blob = dbprop(data: "sr_ck_record_system_property", type: dbprop_types.null, num: 24)
        var cloudkit_record_id = dbprop(data: "cloudkit_record_id", type: dbprop_types.text, num: 25)
        var sr_cloudkit_record_id = dbprop(data: "sr_cloudkit_record_id", type: dbprop_types.null, num: 26)
        var last_addressed_sim_id = dbprop(data: "last_addressed_sim_id", type: dbprop_types.text, num: 27)
        var is_blackholed = dbprop(data: "is_blackholed", type: dbprop_types.int, num: 28)
        var num_items = 29
        subscript(index: Int) -> dbprop {
            let items = [ROWID, guid, style, state, account_id, properties, chat_identifier, service_name, room_name, account_login, is_archived, last_addressed_handle, display_name, group_id, is_filtered, successful_query, engram_id, server_change_token, ck_sync_state, last_read_message_timestamp, ck_record_system_property_blob, original_group_id, sr_server_change_token, sr_ck_sync_state, sr_ck_record_system_property_blob, cloudkit_record_id, sr_cloudkit_record_id, last_addressed_sim_id, is_blackholed]
            return items[index]
        }
    }
    
    class message_dbprops {
        var ROWID = dbprop(data: "ROWID", type: dbprop_types.int, num: 0)
        var guid = dbprop(data: "guid", type: dbprop_types.text, num: 1)
        var text = dbprop(data: "text", type: dbprop_types.text, num: 2)
        var replace = dbprop(data: "replace", type: dbprop_types.int, num: 3)
        var service_center = dbprop(data: "service_center", type: dbprop_types.null, num: 4)
        var handle_id = dbprop(data: "handle_id", type: dbprop_types.int, num: 5)
        var subject = dbprop(data: "subject", type: dbprop_types.text, num: 6)
        var country = dbprop(data: "country", type: dbprop_types.null, num: 7)
        var attributedBody = dbprop(data: "attributedBody", type: dbprop_types.blob, num: 8)
        var version = dbprop(data: "version", type: dbprop_types.int, num: 9)
        var type = dbprop(data: "type", type: dbprop_types.int, num: 10)
        var service = dbprop(data: "service", type: dbprop_types.text, num: 11)
        var account = dbprop(data: "account", type: dbprop_types.text, num: 12)
        var account_guid = dbprop(data: "account_guid", type: dbprop_types.text, num: 13)
        var error = dbprop(data: "error", type: dbprop_types.int, num: 14)
        var date = dbprop(data: "date", type: dbprop_types.text, num: 15)
        var date_read = dbprop(data: "date_read", type: dbprop_types.text, num: 16)
        var date_delivered = dbprop(data: "date_delivered", type: dbprop_types.text, num: 17)
        var is_delivered = dbprop(data: "is_delivered", type: dbprop_types.int, num: 18)
        var is_from_me = dbprop(data: "is_from_me", type: dbprop_types.int, num: 21)
        var cache_roomnames = dbprop(data: "cache_roomnames", type: dbprop_types.text, num: 35)
        var is_audio_message = dbprop(data: "is_audio_message", type: dbprop_types.int, num: 38)
        var is_played = dbprop(data: "is_played", type: dbprop_types.int, num: 39) // Only applies to audio messages
        var group_title = dbprop(data: "group_title", type: dbprop_types.text, num: 43)
        var associated_message_guid = dbprop(data: "associated_message_guid", type: dbprop_types.text, num: 51)
        var destination_caller_id = dbprop(data: "destination_caller_id", type: dbprop_types.text, num: 63)
        var num_items: Int = 26 //Just how many other dbprop items are here
        subscript(index: Int) -> dbprop {
            let total_items = [ROWID, guid, text, replace, service_center, handle_id, subject, country, attributedBody, version, type, service, account, account_guid, error, date, date_read, date_delivered, is_delivered, is_from_me, cache_roomnames, is_audio_message, is_played, group_title, associated_message_guid, destination_caller_id]
            return total_items[index]
        }
        
    }
    
    func loadServer() {
        self.server["/main"] = scopes {
          html {
            Swifter.body {
              h1 { inner = "hello. This is a server running off my phone." }
                if self.messages_have_been_loaded {
                    h2 {
                        inner = "This should be the last text rebecca sent me: \(self.test_messages[self.test_messages.count - 1][0])"
                    }
                } else {
                    h2 {
                        inner = "Messages have not been loaded yet"
                    }
                }
            }
          }
        }
        self.server["/sock"] = websocket(text: { socket, text in
            
        })
        do {
            try self.server.start(8080)
            print("Server is running!")
        } catch {
            print("Ran into an error with running the server :/")
        }
    }
    
    func stopServer() {
        self.server.stop()
    }
    
    func createConnection() -> OpaquePointer? {
        var db: OpaquePointer?
        guard sqlite3_open(messagesURL.path, &db) == SQLITE_OK else {
            print("error opening database")
            sqlite3_close(db)
            db = nil
            return db
        }
        
        return db
    }
    
    func selectFromSql(db: OpaquePointer?, columns: [String], table: String, condition: String = "", num_items: Int = 0) -> [[String]] { /// Flawless.
        """
        columns is the ??? in 'SELECT ???'
        table is the ??? in 'FROM ???'
        condition is the (eg) 'WHERE ROW=1'
        numToSelect is the number of items to return, do all of them if it's 0.
        """
        
        var sqlString = "SELECT "
        for i in columns {
            sqlString += i
            if i != columns[columns.count - 1] {
                sqlString += ", "
            }
        }
        sqlString += " FROM " + table
        if condition != "" {
            sqlString += " " + condition
        }
        sqlString += ";"
        
        if sqlString.contains("@") {
            sqlString = sqlString.replacingOccurrences(of: "@", with: "\\@") /// Lolll guess I gotta escape my escape slash for the '@'
        }
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
        }
        
        var main_return: [[String]] = []
        
        if num_items != 0 {
            var i = 0
            while sqlite3_step(statement) == SQLITE_ROW && i < num_items {
                var minor_return: [String] = []
                for j in 0..<columns.count {
                    var tiny_return = ""
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    } else {
                        print("Nothing returned for tiny_return_cstring when num_items != 0")
                    }
                    minor_return.append(tiny_return)
                }
                main_return.append(minor_return)
                i += 1
            }
        } else {
            while sqlite3_step(statement) == SQLITE_ROW {
                var minor_return: [String] = []
                for j in 0..<columns.count {
                    var tiny_return = ""
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    } else {
                        print("Nothing returned for tiny_return_cstring when num_items != 0")
                    }
                    minor_return.append(tiny_return)
                }
                main_return.append(minor_return)
            }
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error finalizing prepared statement: \(errmsg)")
        }

        statement = nil
        
        print("destroyed statement")
        
        return main_return
    }
    
    func loadMessages(num: String = "+15203106053") -> [[String]] { /// Ok so this function works. Model the other functions off of it
        
        var db = createConnection()
        
        let chat_id_array = selectFromSql(db: db, columns: ["*"], table: "chat", condition: "WHERE chat_identifier = \"\(num)\"", num_items: 1)
        let chat_id = chat_id_array[0][0]
        
        let chat_message_connection_array = selectFromSql(db: db, columns: ["message_id"], table: "chat_message_join", condition: "WHERE chat_id=\"\(chat_id)\"")
        var message_ids: [String] = []
        for i in chat_message_connection_array {
            message_ids.append(i[0])
        }
        
        var messages: [[String]] = []
        
        for i in message_ids {
            let m = selectFromSql(db: db, columns: ["text", "is_from_me"], table: "message", condition: "WHERE ROWID=\(i)", num_items: 1)
            messages.append(m[0]) /// Since it should be an array with just one element
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            print("error closing database")
        }

        db = nil
        
        print("destroyed db")
        
        print("returning messages!")
        messages_have_been_loaded = true
        return messages
    }
    
    var body: some View {
        VStack {
            Text("We're workin' on it!")
            Spacer()
                .frame(height: 20)
            //TextField("***VERY IMPORTANT: DO NOT SCREW THIS UP** enter sql command here", text: $egnum)
            Button(action: {
                self.test_messages = self.loadMessages()
            }) {
                Text("Press me to load messages")
            }
            Spacer()
                .frame(height: 20)
            Button(action: {
                self.loadServer()
                print("Server has fully been loaded up")
            }) {
                Text("Press me to start the server")
            }
            Spacer()
                .frame(height: 20)
            Button(action: {
                self.stopServer()
                print("Server has fully been stopped")
            }) {
                Text("Press me to stop the server")
            }
            if messages_have_been_loaded {
                List(test_messages, id: \.self) { text in
                    Text("\(text[0]), \(text[1])")
                }
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

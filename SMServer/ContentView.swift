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
    @State var test_messages = [[String: String]]()
    @State var messages_have_been_loaded = false
    @State var egnum = "8080"
    let messagesURL = URL(fileURLWithPath: "/private/var/mobile/Library/SMS/sms.db")
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    var requests_page = """
    <!DOCTYPE html>
        <body style="background-color: #222;">
            <p style="color: #DDD; font-family: Verdana; font-size: 24px;">
                This is a niceness test!
            </p>
        </body>
    </html>
    """
    @State var main_page =
    """
    """
    
    func loadServer(port_num: UInt16 = 8080) {
        self.server["/"] = {request in
            return .ok(.text(self.main_page))
        }
        self.server["/requests"] = { request in
            /*print(request.body)
            print(request.address ?? "No address")
            print(request.params)
            print(request.headers)
            print(request.method)*/
            print(request.queryParams)
            //print(request.self)
            if request.queryParams.count == 0 {
                return .ok(.text(self.requests_page)) /// Ok so plain text is interpreted as html. We can totally do css & js.
            } else {
                let return_val = self.parseAndReturn(params: request.queryParams)
                return .ok(.text(return_val))
            }
        }
        do {
            try self.server.start(port_num)
            print("Server is running!")
        } catch {
            print("Ran into an error with running the server :/")
        }
    }
    
    func loadHtmlFile() {
        if let dir = Bundle.main.url(forResource: "chats", withExtension: "html", subdirectory: "html") {
            //print(dir)
            do {
                self.main_page = try String(contentsOf: dir, encoding: .utf8)
            }
            catch {
                print("ran into an error with loading the file, try again.")
            }
        }
    }
    
    func encodeToJson(object: Any, title: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
            return ""
        }
        var data_string = String(decoding: data, as: UTF8.self)
        data_string = "{ \"\(title)\": \(data_string)\n}"
        return data_string
    }
    
    func parseAndReturn(params: [(String, String)]) -> String {
        var person: String = ""
        var selectingPerson = false
        var num_texts = 0
        var selectingChat = false
        var chat_id = ""
        var gettingName = false
        var gettingImage = false
        switch params[0].0 {
        case "p":
            person = params[0].1
            selectingPerson = true
            if params.count > 1 {
                if params[1].0 == "n" {
                    num_texts = Int(params[1].1)!
                }
            }
        case "c":
            selectingChat = true
        case "n":
            chat_id = params[0].1
            //print("chat:" + chat_id)
            gettingName = true
        case "i":
            chat_id = params[0].1
            //print("image chat id: " + chat_id)
            gettingImage = true;
        default:
            print("We haven't implemented any other functionality yet, sorry :/")
        }
        
        if selectingPerson {
            if person.contains("\"") { /// Just in case, I guess?
                person = person.replacingOccurrences(of: "\"", with: "")
            }
            let texts_array = loadMessages(num: person, num_items: num_texts)
            let texts = encodeToJson(object: texts_array, title: "texts")
            return texts
        } else if selectingChat {
            let chats_array = loadChats(num_to_load: 30)
            let chats = encodeToJson(object: chats_array, title: "chats")
            return chats
        } else if gettingName {
            let name = getDisplayName(chat_id: chat_id)
            //print("name: " + name)
            return name
        } else if gettingImage {
            let image_string = returnImageBase64(chat_id: chat_id)
            //print("image 64: " + image_string)
            return image_string
        }
        
        return ""
    }
    
    func stopServer() {
        self.server.stop()
    }
    
    func createConnection(connection_string: String = "/private/var/mobile/Library/SMS/sms.db") -> OpaquePointer? {
        var db: OpaquePointer?
        let connection_url = URL(fileURLWithPath: connection_string)
        guard sqlite3_open(connection_url.path, &db) == SQLITE_OK else {
            print("error opening database")
            sqlite3_close(db)
            db = nil
            return db
        }
        
        print("opened database")
        
        return db
    }
    
    func selectFromSql(db: OpaquePointer?, columns: [String], table: String, condition: String = "", num_items: Int = 0) -> [[String:String]] { /// Flawless.
        
        var sqlString = "SELECT "
        for i in columns {
            sqlString += i
            if i != columns[columns.count - 1] {
                sqlString += ", "
            }
        }
        sqlString += " from " + table
        if condition != "" {
            sqlString += " " + condition
        }
        if num_items != 0 {
            sqlString += " LIMIT \(String(num_items))"
        }
        sqlString += ";"
        
        print("full sql query: " + sqlString)
        
        var statement: OpaquePointer?
        
        print("opened statement")
        
        if sqlite3_prepare_v2(db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
        }
        
        var main_return = [[String:String]]()
        
        if num_items != 0 {
            var i = 0
            while sqlite3_step(statement) == SQLITE_ROW && i < num_items {
                var minor_return = [String:String]()
                for j in 0..<columns.count {
                    var tiny_return = ""
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    } else {
                        print("Nothing returned for tiny_return_cstring when num_items != 0")
                    }
                    //minor_return.append(tiny_return)
                    minor_return[columns[j]] = tiny_return
                }
                main_return.append(minor_return)
                i += 1
            }
        } else {
            while sqlite3_step(statement) == SQLITE_ROW {
                var minor_return = [String:String]()
                for j in 0..<columns.count {
                    var tiny_return = ""
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    } else {
                        print("Nothing returned for tiny_return_cstring when num_items != 0")
                    }
                    minor_return[columns[j]] = tiny_return
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
    
    func getDisplayName(chat_id: String) -> String {
        var db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        
        var display_name_array = [[String:String]]()
        
        if chat_id.contains("@") {
            display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"")
        } else {
            let new_chat_id = chat_id.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if chat_id.count < 7 {
                let chat_id_zero = new_chat_id[new_chat_id.startIndex ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: 3, limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)]
                let chat_id_one = new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: 3, limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< new_chat_id.endIndex]
                display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"\(new_chat_id)\" OR c16Phone LIKE \"\(chat_id_zero)_\(chat_id_one)\"", num_items: 1)
            } else {
                let chat_id_zero = String(new_chat_id[new_chat_id.startIndex ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 10), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_one = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 10), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 7), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_two = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 7), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 4), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_three = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 4), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< new_chat_id.endIndex])
                display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id_zero)%\(chat_id_one)%\(chat_id_two)%\(chat_id_three)%\"", num_items: 1)
            }
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            print("error closing database")
        }

        db = nil
        
        print("destroyed db")
        
        if display_name_array.count != 0 {
            let full_name: String = (display_name_array[0]["c0First"] ?? "no_first") + " " + (display_name_array[0]["c1Last"] ?? "no_last")
            return full_name
        }
        
        return ""
    }
    
    func getDisplayNameWithDb(db: OpaquePointer?, chat_id: String) -> String {
        
        var display_name_array = [[String:String]]()
        
        if chat_id.contains("@") {
            display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"")
        } else {
            let new_chat_id = chat_id.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if chat_id.count < 7 {
                let chat_id_zero = String(new_chat_id[new_chat_id.startIndex ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: 3, limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_one = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: 3, limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< new_chat_id.endIndex])
                display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"\(new_chat_id)\" OR c16Phone LIKE \"\(chat_id_zero)_\(chat_id_one)\"", num_items: 1)
            } else {
                let chat_id_zero = String(new_chat_id[new_chat_id.startIndex ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 10), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_one = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 10), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 7), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_two = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 7), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 4), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_three = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 4), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< new_chat_id.endIndex])
                display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id_zero)%\(chat_id_one)%\(chat_id_two)%\(chat_id_three)%\"", num_items: 1)
            }
        }
        
        if display_name_array.count != 0 {
            let full_name: String = (display_name_array[0]["c0First"] ?? "no_first") + " " + (display_name_array[0]["c1Last"] ?? "no_last")
            return full_name
        }
        
        return ""
    }
    
    func loadMessages(num: String = "+15203106053", num_items: Int = 0) -> [[String:String]] { /// Ok so this function seems to work. cool.
        
        var db = createConnection()
        
        let chat_id_array = selectFromSql(db: db, columns: ["*"], table: "chat", condition: "WHERE chat_identifier = \"\(num)\"", num_items: 1)
        let chat_id = chat_id_array[0]["*"]! /// ! is necessary or else it prints as 'Optional('x')' instead of just 'x'. May cause issues when nothing is returned tho.
        
        var chat_message_connection_array = [[String:String]]()
        
        if num_items == 0 {
            chat_message_connection_array = selectFromSql(db: db, columns: ["message_id"], table: "chat_message_join", condition: "WHERE chat_id=\"\(String(describing: chat_id))\"")
        } else {
            chat_message_connection_array = selectFromSql(db: db, columns: ["message_id"], table: "chat_message_join", condition: "WHERE chat_id=\"\(String(describing: chat_id))\" ORDER BY message_date DESC",  num_items: num_items)
            chat_message_connection_array.reverse()
        }
        var message_ids: [String] = []
        for i in chat_message_connection_array {
            message_ids.append(i["message_id"] ?? "")
        }
        
        var messages = [[String:String]]()
        
        var j = 0
        for i in message_ids {
            let m = selectFromSql(db: db, columns: ["text", "is_from_me", "date", "service"], table: "message", condition: "WHERE ROWID=\(i)", num_items: 1)
            messages.append(m[0]) /// Since it should be an array with just one element, which is a dictionary.
            j += 1
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
    
    func loadChats(num_to_load: Int = 0) -> [[String:String]] {
        var db = createConnection()
        var contacts_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        
        var chats_array = selectFromSql(db: db, columns: ["ROWID", "chat_identifier", "display_name"], table: "chat", condition: "ORDER BY last_read_message_timestamp DESC", num_items: num_to_load)
        
        for i in 0..<chats_array.count {
            if chats_array[i]["display_name"]!.count == 0 {
                chats_array[i]["display_name"] = getDisplayNameWithDb(db: contacts_db, chat_id: chats_array[i]["chat_identifier"]!)
            }
        }
        
        if sqlite3_close(contacts_db) != SQLITE_OK {
            print("error closing database")
        }

        contacts_db = nil
        
        if sqlite3_close(db) != SQLITE_OK {
            print("error closing database")
        }

        db = nil
        
        print("destroyed db")
        
        return chats_array
    }
    
    func returnImageBase64(chat_id: String) -> String {
        var contact_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        
        var docid = [[String:String]]()
        
        if chat_id.contains("@") {
            docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"", num_items: 1)
        } else {
            let new_chat_id = chat_id.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if new_chat_id.count == 0 {
                return ""
            }
            if chat_id.count < 7 {
                let chat_id_zero = new_chat_id[new_chat_id.startIndex ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: 3, limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)]
                let chat_id_one = new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: 3, limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< new_chat_id.endIndex]
                docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"\(new_chat_id)\" OR c16Phone LIKE \"\(chat_id_zero)_\(chat_id_one)\"", num_items: 1)
            } else {
                let chat_id_zero = String(new_chat_id[new_chat_id.startIndex ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 10), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_one = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 10), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 7), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_two = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 7), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< (new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 4), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex)])
                let chat_id_three = String(new_chat_id[(new_chat_id.index(new_chat_id.startIndex, offsetBy: (new_chat_id.count - 4), limitedBy: new_chat_id.endIndex) ?? new_chat_id.endIndex) ..< new_chat_id.endIndex])
                docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id_zero)%\(chat_id_one)%\(chat_id_two)%\(chat_id_three)%\"", num_items: 1)
            }
        }
        
        if docid.count == 0 {
            
            if sqlite3_close(contact_db) != SQLITE_OK {
                print("error closing database")
            }

            contact_db = nil
            
            let image_dat = UIImage(named: "profile")
            let pngdata = image_dat?.pngData()
            let image = pngdata!.base64EncodedString(options: .lineLength64Characters)
            
            return image
        }
        
        var image_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb")
        
        let sqlString = "SELECT data FROM ABThumbnailImage WHERE record_id=\"\(String(describing: docid[0]["docid"]!))\""
        
        var image: String = "";
        
        var statement: OpaquePointer?
        
        print("opened statement")
        
        if sqlite3_prepare_v2(image_db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(image_db)!)
            print("error preparing select: \(errmsg)")
        }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            if let tiny_return_blob = sqlite3_column_blob(statement, 0) {
                let len: Int32 = sqlite3_column_bytes(statement, 0)
                let dat: NSData = NSData(bytes: tiny_return_blob, length: Int(len))
                
                let image_w_dat = UIImage(data: Data(dat))
                let pngdata = image_w_dat?.pngData()
                image = pngdata!.base64EncodedString(options: .lineLength64Characters)
                
            } else {
                print("Nothing returned for tiny_return_cstring when num_items != 0. Using default.")
                let image_dat = UIImage(named: "profile")
                let pngdata = image_dat?.pngData()
                image = pngdata!.base64EncodedString(options: .lineLength64Characters)
            }
        } else {
            let image_dat = UIImage(named: "profile")
            let pngdata = image_dat?.pngData()
            image = pngdata!.base64EncodedString(options: .lineLength64Characters)
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(image_db)!)
            print("error finalizing prepared statement: \(errmsg)")
        }

        statement = nil
        
        print("destroyed statement")
        
        if sqlite3_close(contact_db) != SQLITE_OK {
            print("error closing database")
        }

        contact_db = nil
        
        if sqlite3_close(image_db) != SQLITE_OK {
            print("error closing database")
        }

        image_db = nil
        
        //print(image)
        
        return image; /// So uh it should be a base64 encoded string?
    }
    
    var body: some View {
        VStack {
            Text("Connect to port 8080 on your iPhone's private ip from a browser to view your messages")
            Spacer()
                .frame(height: 20)
            HStack {
                Spacer()
                TextField("Enter port number to run server on", text: $egnum)
                    .frame(width: 250)
                Spacer()
            }
            Button(action: {
                self.test_messages = self.loadMessages()
            }) {
                Text("Press me to load messages")
            }
            Spacer()
                .frame(height: 20)
            Button(action: {
                self.stopServer()
                self.loadServer(port_num: UInt16(self.egnum) ?? 8080)
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
            Spacer()
                .frame(height: 20)
            Button(action: {
                self.loadHtmlFile()
                print("HTML Loaded again")
            }) {
                Text("Reload HTML")
            }
        }.onAppear() {
            self.loadServer()
            self.loadHtmlFile()
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

/// In case I still ever need these
/*enum dbprop_types {
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
       
   }*/

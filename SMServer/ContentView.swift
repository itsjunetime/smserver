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
import MessageUI

struct ContentView: View {
    let server = HttpServer()
    let bbheight: CGFloat? = 40
    let bbsize: CGSize = CGSize(width: 1.8, height: 1.8)
    
    @State var server_running = false
    @State var egnum = "8741"
    @State var password = ""
    @State var main_url = ""
    @State var past_latest_texts = [String:[[String:String]]]() /// Should be in the format of [address: [Chats]]
    
    let messagesString = "/private/var/mobile/Library/SMS/sms.db"
    let messagesURL = URL(fileURLWithPath: "/private/var/mobile/Library/SMS/sms.db")
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
    
    private let messageComposeDelegate = MessageComposerDelegate()
    
    func loadServer(port_num: UInt16) {
        self.server["/"] = { request in
            return .badRequest(.text(""))
        }
        self.server["/" + main_url] = { request in
            return .ok(.text(self.main_page))
        }
        self.server["/requests"] = { request in
            //print("body: ")
            //print(request.body)
            //print("address: ")
            print(request.address ?? "No address")
            //print("params: ")
            //print(request.params)
            //print("headers: ")
            //print(request.headers)
            //print("method: " + request.method)
            print(request.queryParams)
            //print(request.self)
            if request.queryParams.count == 0 {
                return .ok(.text(self.requests_page)) /// Ok so plain text is interpreted as html. We can totally do css & js.
            } else {
                let return_val = self.parseAndReturn(params: request.queryParams, address: request.address ?? "")
                return .ok(.text(return_val))
            }
        }
        self.server["/style.css"] = { request in
            return .ok(.text(self.main_page_style))
        }
        /*self.server["/script.js"] = { request in
            return .ok(.text(self.main_page_script))
        }*/
        do {
            try self.server.start(port_num)
            self.server_running = server.operating
            print("Server is running!")
        } catch {
            print("Ran into an error with running the server :/")
        }
    }
    
    func loadFiles() {
        if let h = Bundle.main.url(forResource: "chats", withExtension: "html", subdirectory: "html"),
        let c = Bundle.main.url(forResource: "style", withExtension: "css", subdirectory: "html") {
            do {
                self.main_page = try String(contentsOf: h, encoding: .utf8)
                self.main_page_style = try String(contentsOf: c, encoding: .utf8)
                /*print("mainpage: ")
                print(self.main_page)*/
            }
            catch {
                print("ran into an error with loading the files, try again.")
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
    
    func parseAndReturn(params: [(String, String)], address: String = "") -> String {
        var person = ""
        var selectingPerson = false
        var num_texts = 0
        
        var selectingChat = false
        
        var chat_id = ""
        var gettingName = false
        
        var gettingImage = false
        
        var sendingText = false
        var sendBody = ""
        var sendAddress = ""
        
        var checkingTexts = false
        
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
            gettingName = true
        case "i":
            chat_id = params[0].1
            gettingImage = true
        case "s":
            sendingText = true
            sendBody = params[0].1
            sendAddress = params[1].1
        case "x":
            checkingTexts = true
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
            DispatchQueue.main.async {
                self.setFirstTexts(address: address);
            }
            return chats
            
        } else if gettingName {
            
            let name = getDisplayName(chat_id: chat_id)
            return name
            
        } else if gettingImage {
            
            let image_string = returnImageBase64(chat_id: chat_id)
            return image_string
            
        } else if sendingText {
            
            sendText(body: sendBody, address: [sendAddress])
            
        } else if checkingTexts {
            
            let lt = encodeToJson(object: checkLatestTexts(address: address), title: "chat_ids")
            print("lt:")
            print(lt)
            return lt
            
        }
        
        return ""
    }
    
    func stopServer() {
        self.server.stop()
        print("Stopped server")
        server_running = server.operating
    }
    
    func sendText(body: String, address: [String]) {
        self.presentMessageCompose(body: body, address: address)
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
    
    func loadMessages(num: String, num_items: Int = 0) -> [[String:String]] { /// Ok so this function seems to work. cool.
        
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
        //messages_have_been_loaded = true
        return messages
    }
    
    func loadChats(num_to_load: Int = 0) -> [[String:String]] {
        var db = createConnection()
        var contacts_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        var image_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb")
        
        ///select * from chat_message_join where message_date in (select max(message_date) from chat_message_join group by chat_id) order by message_date desc; is what we need to get the chat ids
        
        /// This section will get get me an array of the chat ids in order of most recently sent/received text. first is most recent.
        var chat_ids_ordered = selectFromSql(db: db, columns: ["chat_id"], table: "chat_message_join", condition: "where message_date in (select max(message_date) from chat_message_join group by chat_id) order by message_date desc");
        
        var orig_chats_array = selectFromSql(db: db, columns: ["ROWID", "chat_identifier", "display_name"], table: "chat", condition: "ORDER BY last_read_message_timestamp DESC", num_items: num_to_load)
        
        var chats_array = [[String:String]]()
        
        /// Ok this section is kinda terrible and can definitely be optimized.
        for i in 0..<chat_ids_ordered.count {
            let ci = chat_ids_ordered[i]["chat_id"]
            //print(ci ?? "val not found")
            for l in 0..<orig_chats_array.count {
                if orig_chats_array[l]["ROWID"] == ci {
                    //print("matched. ri: \(orig_chats_array[l]["ROWID"]), ci: \(orig_chats_array[l]["chat_identifier"]), dn: \(orig_chats_array[l]["display_name"])")
                    chats_array.append(orig_chats_array[l])
                }
            }
        }

        /// Just saving memory
        chat_ids_ordered = [[String:String]]()
        orig_chats_array = [[String:String]]()
        
        for i in 0..<chats_array.count {
            if chats_array[i]["display_name"]!.count == 0 {
                chats_array[i]["display_name"] = getDisplayNameWithDb(db: contacts_db, chat_id: chats_array[i]["chat_identifier"]!)
            }
            
            chats_array[i]["image_text"] = returnImageBase64DB(chat_id: chats_array[i]["chat_identifier"]!, contact_db: contacts_db!, image_db: image_db!)
        }
        
        if sqlite3_close(image_db) != SQLITE_OK {
            print("error closing image db")
        }
        
        image_db = nil
        
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
        
        var image: String = ""
        
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
        
        return image /// So uh it should be a base64 encoded string?
    }
    
    func returnImageBase64DB(chat_id: String, contact_db: OpaquePointer, image_db: OpaquePointer) -> String {
        //var contact_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        
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
            
            /*if sqlite3_close(contact_db) != SQLITE_OK {
                print("error closing database")
            }

            contact_db = nil*/
            
            let image_dat = UIImage(named: "profile")
            let pngdata = image_dat?.pngData()
            let image = pngdata!.base64EncodedString(options: .lineLength64Characters)
            
            return image
        }
        
        //var image_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb")
        
        let sqlString = "SELECT data FROM ABThumbnailImage WHERE record_id=\"\(String(describing: docid[0]["docid"]!))\""
        
        var image: String = ""
        
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
        
        /*if sqlite3_close(contact_db) != SQLITE_OK {
            print("error closing database")
        }

        contact_db = nil*/
        
        /*if sqlite3_close(image_db) != SQLITE_OK {
            print("error closing database")
        }

        image_db = nil*/
        
        //print(image)
        
        return image /// So uh it should be a base64 encoded string?
    }
    
    func setFirstTexts(address: String) {
        past_latest_texts[address] = getLatestTexts();
    }
    
    func checkLatestTexts(address: String) -> [String] {
        print("Ran checkLatestTexts(\(address))")
        var db = createConnection()
        let latest_texts = getLatestTexts()
        let ap_latest_texts = past_latest_texts[address]
        if latest_texts == ap_latest_texts {
            print("They're identical.")
            return [] /// If they haven't received any new messages, just return nothing
        }
        
        /*if ap_latest_texts == nil {
            print("Haven't pinged before")
            let string = selectFromSql(db: db, columns: ["chat_identifier"], table: "chat")
            var ret = [String]()
            for i in 0..<string.count {
                ret.append(string[i]["chat_identifier"] ?? "chat_identifier not found")
            }
            return ret
        }*/
        
        var new_texts: [String] = [] /// Will just contain a list of all the chats that have new messages since they've last checked
        for i in 0..<latest_texts.count {
            print("checking between \(String(describing: ap_latest_texts?[i]["text"])) and \(String(describing: latest_texts[i]["text"]))")
            if latest_texts[i] != ap_latest_texts?[i] {
                /// Get chat_identifier of each chat where they have new messages
                let append_num = selectFromSql(db: db, columns: ["chat_identifier"], table: "chat", condition: "where ROWID in (select chat_id from chat_message_join where message_id is \(String(describing: latest_texts[i]["ROWID"]))")
                
                new_texts.append(append_num[0]["chat_identifier"] ?? "")
            }
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            print("error closing database")
        }
        
        db = nil
        
        print("new texts:")
        print(new_texts)
        
        past_latest_texts[address] = latest_texts
        
        return new_texts;
    }
    
    func getLatestTexts() -> [[String:String]] {
        var db = createConnection()
        
        /// Don't know if we need date_read in this one. Let's keep experimenting.
        let latest_texts = selectFromSql(db: db, columns: ["ROWID", "text", "date_read"], table: "message", condition: "where ROWID in (select message_id from chat_message_join group by chat_id)" )
        
        print("Latest texts:")
        print(latest_texts)
        
        if sqlite3_close(db) != SQLITE_OK {
            print("error closing database")
        }
        
        db = nil
        
        return latest_texts
    }
    
    func checkIfLatestTexts() -> [[String:String]] {
        return [[String:String]]()
    }
    
    func loadBundle() {
        
        /*var obj_c = obj_class()
        obj_c.loadBundle()*/
        
    }
    
    func getWiFiAddress() -> String? {
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
    
    func sendAttachment() {
        
    }
    
    func displaySettings() {
        
    }
    
    var body: some View {
        NavigationView {
                VStack {
                    Text("Visit \(self.getWiFiAddress() ?? "your phone's private IP, port "):\(self.egnum) in your browser to view your messages")
                        .font(Font.custom("smallTitle", size: 22))
                        .padding()
                
                    Spacer().frame(height: 20)
                    
                    HStack {
                        VStack {
                            HStack {
                                Text("Change default port").font(.subheadline)
                                Spacer()
                            }
                            
                            TextField("Change default server port", text: $egnum)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Spacer().frame(height: 20)
                            
                            /*HStack {
                                Text("Change requests password (ineffective right now)").font(.subheadline)
                                Spacer()
                            }
                            
                            TextField("Change requests password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                            Spacer().frame(height: 20)*/
                                
                            HStack {
                                Text("Change main chats url").font(.subheadline)
                                Spacer()
                            }
                                
                            TextField("Change main chats url", text: $main_url)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }.padding()
                    
                    Spacer()
                    
                    HStack {
                        
                        HStack {
                            
                            Button(action: {
                                self.loadFiles()
                                /*self.stopServer()
                                self.loadServer(port_num: UInt16(self.egnum)!)*/
                            }) {
                                Image(systemName: "goforward")
                                    .scaleEffect(1.5)
                                    .foregroundColor(Color.purple)
                            }
                            
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
                                self.server_running ? nil : self.loadServer(port_num: UInt16(self.egnum)!)
                            }) {
                                Image(systemName: "play.fill")
                                    .scaleEffect(1.5)
                                    .foregroundColor(self.server_running ? Color.gray : Color.green)
                            }
                            
                        }
                        .padding(10)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                self.displaySettings()
                            }) {
                                Image(systemName: "gear")
                                    .scaleEffect(1.5)
                            }
                        }.padding(10)
                    }
                    .padding()
                    
                }.navigationBarTitle(Text("SMServer").font(.largeTitle))
            
        }
        .onAppear() {
            //self.loadServer(port_num: UInt16(self.egnum)!)
            self.loadFiles()
        }
    }
}

extension ContentView {

    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Customize here
            controller.dismiss(animated: true)
        }
    }
    /// Present an message compose view controller modally in UIKit environment
    private func presentMessageCompose(body: String, address: [String]) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        DispatchQueue.main.async {
            let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
            let composeVC = MFMessageComposeViewController()
            composeVC.body = body
            composeVC.recipients = address
            
            composeVC.messageComposeDelegate = self.messageComposeDelegate
            vc?.present(composeVC, animated: true)
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

/*struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}*/

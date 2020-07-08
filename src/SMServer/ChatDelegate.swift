//
//  ChatDelegate.swift
//  SMServer
//
//  Created by Ian Welker on 7/4/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

import Foundation
import SQLite3
import SwiftUI

class ChatDelegate {
    var debug: Bool = UserDefaults.standard.object(forKey: "debug") == nil ? false : UserDefaults.standard.object(forKey: "debug") as! Bool
    @State var past_latest_texts = [String:[[String:String]]]() /// Should be in the format of [address: [Chats]]
    //@State var past_latest_texts = ["ex": [["ROWID": "0", "test": "example", "date_read": "0"]]]
    @State var past_latest_texts_hashes = 0
    
    internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    func createConnection(connection_string: String = "/private/var/mobile/Library/SMS/sms.db") -> OpaquePointer? {
        /// This simply returns an opaque pointer to the database at $connection_string, allowing for sqlite connections.
        
        var db: OpaquePointer?
        let connection_url = URL(fileURLWithPath: connection_string)
        guard sqlite3_open(connection_url.path, &db) == SQLITE_OK else {
            print("WARNING: error opening database")
            sqlite3_close(db)
            db = nil
            return db
        }
        
        self.debug ? print("opened database") : nil
        
        return db
    }
    
    func selectFromSql(db: OpaquePointer?, columns: [String], table: String, condition: String = "", num_items: Int = -1, offset: Int = 0) -> [[String:String]] {
        /// This executes an SQL query, specifically 'SELECT $columns from $table $condition LIMIT $offset, $num_items', on $db
        
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
        if num_items != -1 || offset != 0 {
            sqlString += " LIMIT \(offset), \(String(num_items))"
        }
        sqlString += ";"
        
        self.debug ? print("full sql query: " + sqlString) : nil
        
        var statement: OpaquePointer?
        
        self.debug ? print("opened statement") : nil
        
        if sqlite3_prepare_v2(db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("WARNING: error preparing select: \(errmsg)")
        }
        
        var main_return = [[String:String]]()
        
        if num_items > 0 {
            var i = 0
            while sqlite3_step(statement) == SQLITE_ROW && i < num_items {
                var minor_return = [String:String]()
                for j in 0..<columns.count {
                    var tiny_return = ""
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    } else {
                        print("WARNING: Nothing returned for tiny_return_cstring when num_items != 0")
                    }
                    self.debug ? print("tiny return: \(tiny_return)") : nil
                    minor_return[columns[j]] = tiny_return
                }
                self.debug ? print(minor_return) : nil
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
                        print("WARNING: Nothing returned for tiny_return_cstring when num_items != 0")
                    }
                    self.debug ? print("tiny return: \(tiny_return)") : nil
                    minor_return[columns[j]] = tiny_return
                }
                self.debug ? print(minor_return) : nil
                main_return.append(minor_return)
            }
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("WARNING: error finalizing prepared statement: \(errmsg)")
        }

        statement = nil
        
        self.debug ? print("destroyed statement") : nil
        
        return main_return
    }
    
    func selectFromSqlWithId(db: OpaquePointer?, columns: [String], table: String, identifier: String, condition: String = "", num_items: Int = 0) -> [String: [String:String]] {
        /// This does the same thing as selectFromSql, but returns a dictionary, for O(1) access, instead of an array, for when it doesn't need to be sorted.
        
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
        
        self.debug ? print("full sql query: " + sqlString) : nil
        
        var statement: OpaquePointer?
        
        self.debug ? print("opened statement") : nil
        
        if sqlite3_prepare_v2(db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("WARNING: error preparing select: \(errmsg)")
        }
        
        var main_return = [String: [String:String]]()
        
        if num_items != 0 {
            var i = 0
            while sqlite3_step(statement) == SQLITE_ROW && i < num_items {
                var minor_return = [String:String]()
                var minor_identifier = ""
                for j in 0..<columns.count {
                    var tiny_return = ""
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    } else {
                        print("WARNING: Nothing returned for tiny_return_cstring when num_items != 0")
                    }
                    minor_return[columns[j]] = tiny_return
                    if columns[j] == identifier {
                        minor_identifier = tiny_return
                    }
                }
                main_return[minor_identifier] = minor_return
                i += 1
            }
        } else {
            while sqlite3_step(statement) == SQLITE_ROW {
                var minor_return = [String:String]()
                var minor_identifier = ""
                for j in 0..<columns.count {
                    var tiny_return = ""
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    } else {
                        print("WARNING: Nothing returned for tiny_return_cstring when num_items == 0")
                    }
                    minor_return[columns[j]] = tiny_return
                    if columns[j] == identifier {
                        minor_identifier = tiny_return
                    }
                }
                main_return[minor_identifier] = minor_return
            }
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("WARNING: error finalizing prepared statement: \(errmsg)")
        }

        statement = nil
        
        self.debug ? print("destroyed statement") : nil
        
        return main_return
    }
    
    func parsePhoneNum(num: String) -> String {
        /// This returns a string with SQL wildcards so that you can enter a phone number (e.g. +12837291837) and match it with something like +1 (283) 729-1837.
        
        let new_num = num.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if new_num.count == 0 {
            return ""
        }
        if num.count <= 7 {
            let num_zero = new_num[new_num.startIndex ..< (new_num.index(new_num.startIndex, offsetBy: 3, limitedBy: new_num.endIndex) ?? new_num.endIndex)]
            let num_one = new_num[(new_num.index(new_num.startIndex, offsetBy: 3, limitedBy: new_num.endIndex) ?? new_num.endIndex) ..< new_num.endIndex]
            return num_zero + "_" + num_one
        } else {
            let num_zero = String(new_num[new_num.startIndex ..< (new_num.index(new_num.startIndex, offsetBy: (new_num.count - 10), limitedBy: new_num.endIndex) ?? new_num.endIndex)])
            let num_one = String(new_num[(new_num.index(new_num.startIndex, offsetBy: (new_num.count - 10), limitedBy: new_num.endIndex) ?? new_num.endIndex) ..< (new_num.index(new_num.startIndex, offsetBy: (new_num.count - 7), limitedBy: new_num.endIndex) ?? new_num.endIndex)])
            let num_two = String(new_num[(new_num.index(new_num.startIndex, offsetBy: (new_num.count - 7), limitedBy: new_num.endIndex) ?? new_num.endIndex) ..< (new_num.index(new_num.startIndex, offsetBy: (new_num.count - 4), limitedBy: new_num.endIndex) ?? new_num.endIndex)])
            let num_three = String(new_num[(new_num.index(new_num.startIndex, offsetBy: (new_num.count - 4), limitedBy: new_num.endIndex) ?? new_num.endIndex) ..< new_num.endIndex])
            return "%" + num_zero + "%" + num_one + "%" + num_two + "%" + num_three + "%"
        }
    }
    
    func getDisplayName(chat_id: String) -> String {
        /// Gets the first + last name of a contact with the phone number or email of $chat_id
        
        var db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        
        var display_name_array = [[String:String]]()
        
        if chat_id.contains("@") {
            display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"")
        } else {
            let parsed_num = parsePhoneNum(num: chat_id)
            
            display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"\(parsed_num)\"", num_items: 1)
            
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            print("WARNING: error closing database")
        }

        db = nil
        
        self.debug ? print("destroyed db") : nil
        
        if display_name_array.count != 0 {
            let full_name: String = (display_name_array[0]["c0First"] ?? "no_first") + " " + (display_name_array[0]["c1Last"] ?? "no_last")
            return full_name
        }
        
        return ""
    }
    
    func getDisplayNameWithDb(db: OpaquePointer?, chat_id: String) -> String {
        /// This does the same thing as getDisplayName, but with the database as an argument. This allows batch display name fetching to be much faster
        /// than if you had to remake the database for each display name that you wanted to fetch.
        
        var display_name_array = [[String:String]]()
        
        if chat_id.contains("@") {
            display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"")
        } else {
            let parsed_num = parsePhoneNum(num: chat_id)
            display_name_array = selectFromSql(db: db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"\(parsed_num)\"", num_items: 1)
            
        }
        
        if display_name_array.count != 0 {
            let full_name: String = (display_name_array[0]["c0First"] ?? "no_first") + " " + (display_name_array[0]["c1Last"] ?? "no_last")
            return full_name
        }
        
        return ""
    }
    
    func loadMessages(num: String, num_items: Int, offset: Int = 0) -> [[String:String]] {
        /// This loads the latest $num_items messages from/to $num, offset by $offset.
        
        var db = createConnection()
        
        var messages = selectFromSql(db: db, columns: ["ROWID", "text", "is_from_me", "date", "service", "cache_has_attachments"], table: "message", condition: "WHERE ROWID IN (SELECT message_id FROM chat_message_join WHERE chat_id IN (SELECT ROWID from chat WHERE chat_identifier is \"\(num)\") ORDER BY message_date DESC) ORDER BY date DESC", num_items: num_items, offset: offset)
        
        for i in 0..<messages.count {
            if messages[i]["cache_has_attachments"] == "1" {
                let a = getAttachmentFromMessage(mid: messages[i]["ROWID"]!)
                var file_string = ""
                var type_string = ""
                self.debug ? print(a) : nil
                for i in 0..<a.count {
                    file_string += a[i][0]
                    file_string += i != a.count ? ":" : ""
                    type_string += a[i][1]
                    type_string += i != a.count ? ":" : ""
                }
                messages[i]["attachment_file"] = file_string
                messages[i]["attachment_type"] = type_string
            }
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            print("WARNING: error closing database")
        }

        db = nil
        
        self.debug ? print("destroyed db") : nil
        
        self.debug ? print("returning messages!") : nil
        
        if self.debug {
            for i in messages { print(i) }
        }
        
        return messages
    }
    
    func loadChats(num_to_load: Int, offset: Int = 0) -> [[String:String]] {
        /// This loads the most recent $num_to_load conversations, offset by $offset
        
        var db = createConnection()
        var contacts_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        var image_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb")
        
        let messages = selectFromSqlWithId(db: db, columns: ["ROWID", "is_read", "is_from_me", "text", "item_type", "date_read"], table: "message", identifier: "ROWID", condition: "WHERE ROWID in (select message_id from chat_message_join where message_date in (select max(message_date) from chat_message_join group by chat_id) order by message_date desc)")
        let chat_ids_ordered = selectFromSql(db: db, columns: ["chat_id", "message_id"], table: "chat_message_join", condition: "where message_date in (select max(message_date) from chat_message_join group by chat_id) order by message_date desc", num_items: num_to_load, offset: offset)
        let chats = selectFromSqlWithId(db: db, columns: ["ROWID", "chat_identifier", "display_name"], table: "chat", identifier: "ROWID", condition: "WHERE ROWID in (select chat_id from chat_message_join where message_date in (select max(message_date) from chat_message_join group by chat_id))")
        
        var chats_array = [[String:String]]()
        var already_selected = [String:Int]() /// Just making it a dictionary so I have O(1) access instead of iterating through, as with an array
        
        for i in chat_ids_ordered {
            if chats[i["chat_id"] ?? ""] == nil {
                continue
            }
            
            let ci = chats[i["chat_id"]!]!["chat_identifier"]
            
            if already_selected[ci!] != nil {
                continue;
            }
            
            var new_chat = chats[i["chat_id"]!]
            
            new_chat!["has_unread"] = "false"
            if messages[i["message_id"]!]!["is_from_me"] == "0" && messages[i["message_id"]!]!["date_read"] == "0" && messages[i["message_id"]!]!["text"] != nil && messages[i["message_id"]!]!["is_read"] == "0" && messages[i["message_id"]!]!["item_type"] == "0" {
                self.debug ? print(messages[i["message_id"]!] as Any) : nil
                new_chat!["has_unread"] = "true"
            }
            
            if new_chat?["display_name"]!.count == 0 {
                new_chat?["display_name"] = getDisplayNameWithDb(db: contacts_db, chat_id: ci ?? "")
            }
            
            self.debug ? print(new_chat!) : nil
            
            chats_array.append(new_chat!)
            already_selected[ci!] = 0
        }
        
        if sqlite3_close(image_db) != SQLITE_OK {
            print("WARNING: error closing image db")
        }
        
        image_db = nil
        
        if sqlite3_close(contacts_db) != SQLITE_OK {
            print("WARNING: error closing database")
        }

        contacts_db = nil
        
        if sqlite3_close(db) != SQLITE_OK {
            print("WARNING: error closing database")
        }

        db = nil
        
        self.debug ? print("destroyed db") : nil
        
        return chats_array
    }
    
    func returnImageData(chat_id: String) -> Data {
        /// This returns the profile picture for someone with the phone number or email $chat_id as pure image data
        
        var contact_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        var image_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb")
        
        let return_val = returnImageDataDB(chat_id: chat_id, contact_db: contact_db!, image_db: image_db!)
        
        if sqlite3_close(contact_db) != SQLITE_OK {
            print("WARNING: error closing database")
        }

        contact_db = nil
        
        if sqlite3_close(image_db) != SQLITE_OK {
            print("WARNING: error closing database")
        }

        image_db = nil
        
        return return_val
    }
    
    func returnImageDataDB(chat_id: String, contact_db: OpaquePointer, image_db: OpaquePointer) -> Data {
        /// This does the same thing as returnImageDB, but with the contact_db and image_db as arguments, allowing for optimized batch profile image fetching
        
        var docid = [[String:String]]()
        
        if chat_id.contains("@") {
            docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"", num_items: 1)
        } else {
            let parsed_num = parsePhoneNum(num: chat_id)
            docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"\(parsed_num)\"", num_items: 1)
        }
        
        if docid.count == 0 {
            
            let image_dat = UIImage(named: "profile")
            let pngdata = (image_dat?.pngData())!
            
            return pngdata
        }
            
        let sqlString = "SELECT data FROM ABThumbnailImage WHERE record_id=\"\(String(describing: docid[0]["docid"]!))\""
        
        var statement: OpaquePointer?
        
        self.debug ? print("opened statement") : nil
        
        if sqlite3_prepare_v2(image_db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(image_db)!)
            print("WARNING: error preparing select: \(errmsg)")
        }
        
        var pngdata: Data;
        
        if sqlite3_step(statement) == SQLITE_ROW {
            if let tiny_return_blob = sqlite3_column_blob(statement, 0) {
                let len: Int32 = sqlite3_column_bytes(statement, 0)
                let dat: NSData = NSData(bytes: tiny_return_blob, length: Int(len))
                
                let image_w_dat = UIImage(data: Data(dat))
                pngdata = (image_w_dat?.pngData())!
                
            } else {
                print("WARNING: Nothing returned for tiny_return_cstring when num_items != 0. Using default.")
                let image_dat = UIImage(named: "profile")
                pngdata = (image_dat?.pngData())!
            }
        } else {
            let image_dat = UIImage(named: "profile")
            pngdata = (image_dat?.pngData())!
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(image_db)!)
            print("WARNING: error finalizing prepared statement: \(errmsg)")
        }

        statement = nil
        
        self.debug ? print("destroyed statement") : nil
        
        return pngdata
    }
    
    func setFirstTextsHash(address: String) {
        let inner = getLatestTexts()
        
        var hasher = Hasher()
        hasher.combine(inner)
        let hash = hasher.finalize()
        
        past_latest_texts_hashes = hash
    }
    
    func checkLatestTextsHash(address: String) -> Bool {
        
        if past_latest_texts_hashes == 0 {
            return true
        }
        
        let new = getLatestTexts()
        
        var hasher = Hasher()
        hasher.combine(new)
        let hash = hasher.finalize()
        
        if past_latest_texts_hashes != hash {
            return true
        } else {
            return false
        }
        
    }
    
    func setFirstTexts(address: String) { /// WHAT. WHAT IS THE ISSUE. WHY CAN I NOT INSERT NESTED DICTIONARIES.
        /// This just sets a variable for the latest texts that one has received, so that it can be compared against
        /// whenever something pings the server to check if they have received more text messages
        
        past_latest_texts[address] = getLatestTexts();
    }
    
    func checkLatestTexts(address: String) -> [String] {
        /// This just checks if the host device has received more texts ever since the ip address $address last pinged the host
        
        self.debug ? print("Ran checkLatestTexts(\(address))") : nil
        var db = createConnection()
        let latest_texts = getLatestTexts()
        //let plt = past_latest_texts
        let ap_latest_texts = past_latest_texts[address]
        if latest_texts == ap_latest_texts {
            self.debug ? print("They're identical.") : nil
            return [] /// If they haven't received any new messages, just return nothing
        }
        
        if ap_latest_texts == nil {
            self.debug ? print("Haven't pinged before") : nil
            let string = selectFromSql(db: db, columns: ["chat_identifier"], table: "chat")
            var ret = [String]()
            for i in 0..<string.count {
                ret.append(string[i]["chat_identifier"] ?? "chat_identifier not found")
            }
            
            self.past_latest_texts[address] = latest_texts
            
            self.debug ? print(past_latest_texts) : nil
            
            return ret
        }
        
        var new_texts: [String] = [] /// Will just contain a list of all the chats that have new messages since they've last checked
        
        for i in 0..<latest_texts.count {
            self.debug ? print("checking between \(String(describing: ap_latest_texts?[i]["text"])) and \(String(describing: latest_texts[i]["text"]))") : nil
            if latest_texts[i] != ap_latest_texts?[i] {
                if let check_message_id = latest_texts[i]["ROWID"] {
                    let append_num = selectFromSql(db: db, columns: ["chat_identifier"], table: "chat", condition: "where ROWID in (select chat_id from chat_message_join where message_id is \(check_message_id))")
                    
                    new_texts.append(append_num[0]["chat_identifier"] ?? "")
                }
            }
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            print("WARNING: error closing database")
        }
        
        db = nil
        
        if self.debug {
            print("new texts:")
            print(new_texts)
        }
        
        past_latest_texts[address] = latest_texts
        
        return new_texts;
    }
    
    func getLatestTexts() -> [[String:String]] {
        /// This simply returns the most recent text from every existing conversation
        
        var db = createConnection()
        
        let latest_texts = selectFromSql(db: db, columns: ["ROWID", "text", "date_read"], table: "message", condition: "WHERE ROWID in (select message_id from chat_message_join where message_date in (select max(message_date) from chat_message_join group by chat_id) order by message_date desc)" )
        
        if sqlite3_close(db) != SQLITE_OK {
            print("WARNING: error closing database")
        }
        
        db = nil
        
        return latest_texts
    }
    
    func getAttachmentFromMessage(mid: String) -> [[String]] {
        /// This returns the file path for all attachments associated with a certain message with the message_id of $mid
        
        let db = createConnection()
        let file = selectFromSql(db: db, columns: ["filename", "mime_type", "hide_attachment"], table: "attachment", condition: "WHERE ROWID in (SELECT attachment_id from message_attachment_join WHERE message_id is \(mid))")
        
        var return_val = [[String]]()
        
        self.debug ? print("attachment file:") : nil
        self.debug ? print(file) : nil
        
        if file.count > 0 {
            for i in file {
                var suffixed = String(i["filename"]?.dropFirst(ContentView.imageStoragePrefix.count - ContentView.userHomeString.count + 2) ?? "")
                suffixed = suffixed.replacingOccurrences(of: "/", with: "._.")
                let type = i["mime_type"] ?? ""
                return_val.append([suffixed, type])
            }
        }
        
        return return_val
    }
    
    func getAttachmentType(path: String) -> String {
        /// This gets the file type of the attachment at $path
        
        let new_path = path.replacingOccurrences(of: "._.", with: "/")
        
        let db = createConnection()
        let file_type_array = selectFromSql(db: db, columns: ["mime_type"], table: "attachment", condition: "WHERE filename like \"%\(new_path)%\"", num_items: 1)
        var return_val = "image/jpeg" /// Most likely thing
        
        if file_type_array.count > 0 {
            return_val = file_type_array[0]["mime_type"]!
        }
        
        return return_val
    }
    
    func getAttachmentDataFromPath(path: String) -> Data {
        /// This returns the pure data of a file (attachment) at $path
        
        let parsed_path = path.replacingOccurrences(of: "._.", with: "/").replacingOccurrences(of: "../", with: "") ///Prevents LFI
        
        do {
            let attachment_data = try Data.init(contentsOf: URL(fileURLWithPath: ContentView.imageStoragePrefix + parsed_path))
            return attachment_data
        } catch {
            print("WARNING: failed to load image for path \(ContentView.imageStoragePrefix + path)")
            return Data.init(capacity: 0)
        }
    }
}

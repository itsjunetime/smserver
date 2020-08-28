import Foundation
import SQLite3
import SwiftUI
import Photos
import os

class ChatDelegate {
    var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
    let prefix = "SMServer_app: "
    
    static let imageStoragePrefix = "/private/var/mobile/Library/SMS/Attachments/"
	static let photoStoragePrefix = "/var/mobile/Media/DCIM/"
    static let userHomeString = "/private/var/mobile/"
    
    func log(_ s: String) {
        /// Logs to syslog/console
        os_log("%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, self.prefix, s)
    }
    
    func createConnection(connection_string: String = "/private/var/mobile/Library/SMS/sms.db") -> OpaquePointer? {
        /// This simply returns an opaque pointer to the database at $connection_string, allowing for sqlite connections.
        
        var db: OpaquePointer?
        
        /// Open the database
        let return_code = sqlite3_open_v2(connection_string, &db, SQLITE_OPEN_READONLY, nil)
        
        if return_code != SQLITE_OK {
            self.log("WARNING: error opening database at \(connection_string): \(return_code)")
            sqlite3_close(db)
            db = nil
            return db
        }
        
        if self.debug {
            self.log("opened database")
        }
        
        /// Return pointer to the database
        return db
    }
    
	func selectFromSql(db: OpaquePointer?, columns: [String], table: String, condition: String = "", num_items: Int = -1, offset: Int = 0) -> [[String:String]] {
        /// This executes an SQL query, specifically 'SELECT $columns from $table $condition LIMIT $offset, $num_items', on $db
        
        /// Construct the query
        var sqlString = "SELECT "
        for i in columns {
            sqlString += i
            if columns.count > 0 && i != columns[columns.count - 1] {
                sqlString += ", "
            }
        }
        sqlString += " from " + table
        if condition != "" {
            sqlString += " " + condition
        }
        if num_items > 0 || offset != 0 {
            sqlString += " LIMIT \(offset), \(String(num_items))"
        }
        sqlString += ";"
        
        if self.debug {
            self.log("full sql query: " + sqlString)
        }
        
        var statement: OpaquePointer?
        
        if self.debug {
            self.log("opened statement")
        }
        
        /// Prepare the database for querying $sqlString
        if sqlite3_prepare_v2(db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            self.log("WARNING: error preparing select: \(errmsg)")
        }
        
        var main_return = [[String:String]]()
        
        /// Separate sections for num_items > 0 and num_items == 0 because if num_items == 0, then it gets all the items,
        /// but otherwise it just gets as many as were asked for
        if num_items > 0 {
            var i = 0
            /// for each row, up to num_items rows
            while sqlite3_step(statement) == SQLITE_ROW && i < num_items {
                var minor_return = [String:String]()
                /// for every column in the row
                for j in 0..<columns.count {
                    var tiny_return = ""
                    /// Get the string for the specific column
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    }
                    /// add it to return value
                    minor_return[columns[j]] = tiny_return
                }
                /// Add it to return value
                main_return.append(minor_return)
                i += 1
            }
        } else {
            /// While we can get a row
            while sqlite3_step(statement) == SQLITE_ROW {
                var minor_return = [String:String]()
                /// For each column in the row
                for j in 0..<columns.count {
                    var tiny_return = ""
                    /// Get the text
                    if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
                        tiny_return = String(cString: tiny_return_cstring)
                    }
                    minor_return[columns[j]] = tiny_return
                }
                main_return.append(minor_return)
            }
        }
        
        /// Finalize; has to be done after getting info.
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            self.log("WARNING: error finalizing prepared statement: \(errmsg)")
        }

        statement = nil
        
        if self.debug {
            self.log("destroyed statement")
        }
        
        /// Since we passed $db in as a parameter, we don't close the database here, but rather in the function where $db was constructed
        return main_return
    }
    
    func getDisplayName(chat_id: String) -> String {
        /// This does the same thing as getDisplayName, but doesn't take db as an argument. This allows for fetching of a single name,
        /// when you don't need to get a lot of names at once.
        
        if self.debug {
            self.log("Getting display name for \(chat_id)")
        }
        
        /// Connect to contact database
        var contact_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        var sms_db = createConnection()
        if contact_db == nil || sms_db == nil { return "" }
        
        /// get name
        let name = getDisplayNameWithDb(sms_db: sms_db, contact_db: contact_db, chat_id: chat_id)
        
        /// close
        if sqlite3_close(sms_db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        sms_db = nil
        
        if sqlite3_close(contact_db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }
        
        contact_db = nil
        
        if self.debug {
            self.log("destroyed db")
        }
        
        return name
    }
    
    func getDisplayNameWithDb(sms_db: OpaquePointer?, contact_db: OpaquePointer?, chat_id: String) -> String {
        /// Gets the first + last name of a contact with the phone number or email of $chat_id
        
        if self.debug {
            self.log("Getting display name for \(chat_id) with db")
        }
        
        var display_name_array = [[String:String]]()
        
        if chat_id.contains("@") { /// if an email
            display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"")
        } else if chat_id.contains("+") {
            /// get first name and last name
            display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id)%\"", num_items: 1)
        } else {
            display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id) \" and c16Phone NOT LIKE \"%+%\"")
        }
        
        if display_name_array.count == 0 {
            let unc = selectFromSql(db: sms_db, columns: ["uncanonicalized_id"], table: "handle", condition: "WHERE id is \"\(chat_id)\"")
            
            guard let ret = unc[0]["uncanonicalized_id"] else {
                return ""
            }
            
            return ret
        }
        
            /// combine first name and last name
        let full_name: String = (display_name_array[0]["c0First"] ?? "no_first") + " " + (display_name_array[0]["c1Last"] ?? "no_last")
        
        if self.debug {
            self.log("full name for \(chat_id) is \(full_name)")
        }
        
        return full_name
    }
    
    func getGroupRecipientsWithDb(contact_db: OpaquePointer?, db: OpaquePointer?, ci: String) -> [String] {
        
        if self.debug {
            self.log("Getting group chat recipients for \(ci)")
        }
        
        let recipients = selectFromSql(db: db, columns: ["id"], table: "handle", condition: "WHERE ROWID in (SELECT handle_id from chat_handle_join WHERE chat_id in (SELECT ROWID from chat where chat_identifier is \"\(ci)\"))")
        
        var ret_val = [String]()
        
        for i in recipients {
            /// Ok this is super lazy but I don't actually return all the group recipients, I just get the first two, then add '...' onto the end
            /// Maybe I'll improve this in the future when I get better at JS & CSS and can display it nicely on the web interface
            if recipients.count > 2 && i == recipients[2] {
                ret_val.append("...")
                break
            }
            
            /// get name for person
            let ds = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: i["id"] ?? "")
            ret_val.append((ds == "" ? i["id"] : ds) ?? "")
        }
        
        if self.debug {
            self.log("Finished retrieving recipients for \(ci)")
        }
        
        return ret_val
    }
    
    func loadMessages(num: String, num_items: Int, offset: Int = 0) -> [[String:String]] {
        /// This loads the latest $num_items messages from/to $num, offset by $offset.
        
        if self.debug {
            self.log("getting messages for \(num)")
        }
        
        /// Create connection to text and contact databases
        var db = createConnection()
        var contact_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        if db == nil || contact_db == nil { return [[String:String]]() }
        
        /// Get the most recent messages and all their relevant metadata from $num
        var messages = selectFromSql(db: db, columns: ["ROWID", "guid", "text", "is_from_me", "date", "service", "cache_has_attachments", "handle_id"], table: "message", condition: "WHERE ROWID IN (SELECT message_id FROM chat_message_join WHERE chat_id IN (SELECT ROWID from chat WHERE chat_identifier is \"\(num)\") ORDER BY message_date DESC) ORDER BY date DESC", num_items: num_items, offset: offset)
        
        /// check if it's a group chat
        let is_group = num.prefix(4) == "chat"
        
        /*let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named*/
        
        /// for each message
        for i in 0..<messages.count {
            /// if it has attachments
            if messages[i]["cache_has_attachments"] == "1" && messages[i]["ROWID"] != nil {
                let a = getAttachmentFromMessage(mid: messages[i]["ROWID"]!) /// get list of attachments
                var file_string = ""
                var type_string = ""
                if self.debug {
                    print(prefix)
                    print(a)
                }
                for l in 0..<a.count {
                    /// use ':' as separater between attachments 'cause you can't have a filename in iOS that contains it (I think?)
                    file_string += a[l][0] + (l != a.count ? ":" : "")
                    type_string += a[l][1] + (l != a.count ? ":" : "")
                }
                messages[i]["attachment_file"] = file_string
                messages[i]["attachment_type"] = type_string
            }
            
            /// get names for each message's sender if it's a group chat
            if is_group && messages[i]["is_from_me"] == "0" && messages[i]["handle_id"] != nil {
                
                let handle = selectFromSql(db: db, columns: ["id"], table: "handle", condition: "WHERE ROWID is \(messages[i]["handle_id"]!)", num_items: 1)
                
                if handle.count > 0 {
                    let name = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: handle[0]["id"]!)
                    
                    messages[i]["sender"] = name
                }
            } else {
                /// if it's not a group chat, or it's from me, or it doesn't have information on who sent it
                messages[i]["sender"] = "nil"
            }
            
            /// Don't think I like showing relative time for messages, so I'll just leave this commented out for now.
            /*let t: Double = ((Double(messages[i]["date"] ?? "0") ?? 0.0) / 1000000000.0) + 978307200.0
            let d = Date(timeIntervalSince1970: t)
            
            messages[i]["relative_time"] = formatter.localizedString(for: d, relativeTo: Date())*/
        }
        
        /// close dbs
        if sqlite3_close(db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        db = nil
        
        if sqlite3_close(contact_db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        contact_db = nil
        
        if self.debug {
            self.log("destroyed db")
            self.log("returning messages!")
        }
        
        return messages
    }
    
    func loadChats(num_to_load: Int, offset: Int = 0) -> [[String:String]] {
        /// This loads the most recent $num_to_load conversations, offset by $offset
        
        if self.debug {
            self.log("Getting chats")
        }
        
        /// Create connections
        var db = createConnection()
        var contacts_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        if db == nil || contacts_db == nil { return [[String:String]]() }
        
        let chats = selectFromSql(db: db, columns: ["m.ROWID", "m.is_read", "m.is_from_me", "m.text", "m.item_type", "m.date_read", "m.date", "m.cache_has_attachments", "c.chat_identifier", "c.display_name", "c.room_name"], table: "chat_message_join j", condition: "inner join message m on j.message_id = m.ROWID inner join chat c on c.ROWID = j.chat_id where j.message_date in (select  max(message_date) from chat_message_join group by chat_id) group by c.chat_identifier order by j.message_date desc", num_items: num_to_load, offset: offset)
        var return_array = [[String:String]]()
        
        let locale = Locale.current
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.dateTimeStyle = .named
        
        for i in chats {
            if self.debug {
                self.log("Beginning to iterate through chats for \(i["c.chat_identifier"]!)")
            }
            
            var new_chat = [String:String]()
            
            /// Check for if it has unread. It has to fit all these specific things.
            new_chat["has_unread"] = (i["m.is_from_me"] == "0" && i["m.date_read"] == "0" && i["m.text"] != nil && i["m.is_read"] == "0" && i["m.item_type"] == "0") ? "true" : "false"
            
            /// Content of the most recent text. If a text has attachments, `i["m.text"]` will look like `\u{ef}`. this checks for that.
            if i["m.text"]?.replacingOccurrences(of: "\u{fffc}", with: "", options: NSString.CompareOptions.literal, range: nil).trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
                new_chat["latest_text"] = i["m.text"]
            } else if i["m.cache_has_attachments"] != "0" {
                let att = getAttachmentFromMessage(mid: i["m.ROWID"] ?? "")
                
                /// Make it say like `Attachment: Image` if there's no text
                if att.count != 0 && att[0].count == 2 {
                    new_chat["latest_text"] = "Attachment: " + att[0][1].prefix(upTo: att[0][1].firstIndex(of: "/") ?? att[0][1].endIndex)
                }
            } else {
                new_chat["latest_text"] = ""
            }
            
            /// Get name for chat
            if i["c.display_name"]!.count == 0 {
                if i["c.room_name"]?.count != 0 {
                    let recipients = getGroupRecipientsWithDb(contact_db: contacts_db, db: db, ci: i["c.chat_identifier"]!)
                    
                    var display_val = ""
                    
                    for r in recipients {
                        display_val += r
                        if recipients.count > 0 && r != recipients[recipients.count - 1] {
                            display_val += ", "
                        }
                    }
                    
                    new_chat["display_name"] = display_val
                } else {
                    new_chat["display_name"] = getDisplayNameWithDb(sms_db: db, contact_db: contacts_db, chat_id: i["c.chat_identifier"]!)
                }
            } else {
                new_chat["display_name"] = i["c.display_name"]
            }
            
            /// Cause `i["h.id"]` is just the `chat_identifier` of one of the members of the group if it's a group chat.
            new_chat["chat_identifier"] = i["c.chat_identifier"]
            new_chat["time_marker"] = i["m.date"]
            
            let t: Double = ((Double(i["m.date"] ?? "0") ?? 0.0) / 1000000000.0) + 978307200.0
            let d = Date(timeIntervalSince1970: t)
            
            new_chat["relative_time"] = formatter.localizedString(for: d, relativeTo: Date())
            
            return_array.append(new_chat)
        }
        
        /// close
        if sqlite3_close(contacts_db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        contacts_db = nil
        
        if sqlite3_close(db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        db = nil
        
        if self.debug {
            self.log("destroyed db")
        }
        
        return return_array
    }
    
    func returnImageData(chat_id: String) -> Data {
        /// This does the same thing as returnImageDataDB, but without the contact_db and image_db as arguments, if you just need to get like 1 image
        
        if self.debug {
            self.log("Getting image data for chat_id \(chat_id)")
        }
        
        /// Make connections
        var contact_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        var image_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb")
        if contact_db == nil || image_db == nil { return Data.init(capacity: 0) }
        
        /// get image data with dbs as parameters
        let return_val = returnImageDataDB(chat_id: chat_id, contact_db: contact_db!, image_db: image_db!)
        
        /// close
        if sqlite3_close(contact_db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        contact_db = nil
        
        if sqlite3_close(image_db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        image_db = nil
        
        return return_val
    }
    
    func returnImageDataDB(chat_id: String, contact_db: OpaquePointer, image_db: OpaquePointer) -> Data {
        /// This returns the profile picture for someone with the phone number or email $chat_id as pure image data
        
        if self.debug {
            self.log("Getting image data with db for chat_id \(chat_id)")
        }
        
        var docid = [[String:String]]()
        
        /// get docid. docid is the identifier that corresponds to each contact, allowing for us to get their image
        
        if chat_id.contains("@") { /// if an email
            docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"")
        } else if chat_id.contains("+") {
            docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id)%\"", num_items: 1)
        } else {
            docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id) \" and c16Phone NOT LIKE \"%+%\"")
        }
        
        /// Use default profile if you don't have them in your contacts
        if docid.count == 0 {
            
            let image_dat = UIImage(named: "profile")
            let pngdata = (image_dat?.pngData())!
            
            return pngdata
        }
            
        /// each contact image is stored as a blob in the sqlite database, not as a file.
        /// That's why we need a special query to get it, and can't use the selectFromSql function(s).
        let sqlString = "SELECT data FROM ABThumbnailImage WHERE record_id=\"\(String(describing: docid[0]["docid"]!))\""
        
        var statement: OpaquePointer?
        
        if self.debug {
            self.log("opened statement")
        }
        
        if sqlite3_prepare_v2(image_db, sqlString, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(image_db)!)
            self.log("WARNING: error preparing select: \(errmsg)")
        }
        
        var pngdata: Data;
        
        if sqlite3_step(statement) == SQLITE_ROW {
            if let tiny_return_blob = sqlite3_column_blob(statement, 0) {
                
                /// Getting the data
                let len: Int32 = sqlite3_column_bytes(statement, 0)
                let dat: NSData = NSData(bytes: tiny_return_blob, length: Int(len))
                
                /// Putting it into UIImage format, then grabbing the image from that
                let image_w_dat = UIImage(data: Data(dat))
                pngdata = (image_w_dat?.pngData())!
                
            } else {
                if self.debug {
                    self.log("No profile picture found. Using default.")
                }
                
                /// Use default profile if you don't have a profile image set for them
                let image_dat = UIImage(named: "profile")
                pngdata = (image_dat?.pngData())!
            }
        } else {
            
            /// Just a backup; use default image
            let image_dat = UIImage(named: "profile")
            pngdata = (image_dat?.pngData())!
        }
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(image_db)!)
            self.log("WARNING: error finalizing prepared statement: \(errmsg)")
        }

        statement = nil
        
        if self.debug {
            self.log("destroyed statement")
        }
        
        return pngdata
    }
    
    func getAttachmentFromMessage(mid: String) -> [[String]] {
        /// This returns the file path for all attachments associated with a certain message with the message_id of $mid
        
        if self.debug {
            self.log("Gettig attachment for mid \(mid)")
        }
        
        /// create connection, get attachments information
        var db = createConnection()
        if db == nil { return [[String]]() }
        
        let file = selectFromSql(db: db, columns: ["filename", "mime_type", "hide_attachment"], table: "attachment", condition: "WHERE ROWID in (SELECT attachment_id from message_attachment_join WHERE message_id is \(mid))")
        
        var return_val = [[String]]()
        
        if self.debug {
            self.log("attachment file length: \(String(file.count))")
        }
        
        if file.count > 0 {
            for i in file {
                
                /// get the path of the attachment minus the attachment storage prefix ("/private/var/mobile/Library/SMS/Attachments/")
                let suffixed = String(i["filename"]?.dropFirst(ChatDelegate.imageStoragePrefix.count - ChatDelegate.userHomeString.count + 2) ?? "")
                let type = i["mime_type"] ?? ""
                
                /// Append to return array
                return_val.append([suffixed, type])
            }
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        db = nil
        
        return return_val
    }
    
    func getAttachmentType(path: String) -> String {
        /// This gets the file type of the attachment at $path
        
        if self.debug {
            self.log("Getting attachment type for @ \(path)")
        }
        
        var db = createConnection()
        if db == nil { return "" }
        
        let file_type_array = selectFromSql(db: db, columns: ["mime_type"], table: "attachment", condition: "WHERE filename like \"%\(path)%\"", num_items: 1)
        var return_val = "image/jpeg" /// Most likely thing
        
        if file_type_array.count > 0 {
            return_val = file_type_array[0]["mime_type"]!
        }
        
        if sqlite3_close(db) != SQLITE_OK {
            self.log("WARNING: error closing database")
        }

        db = nil
        
        return return_val
    }
    
    func getAttachmentDataFromPath(path: String) -> Data {
        /// This returns the pure data of a file (attachment) at $path
        
        if self.debug {
            self.log("Getting attachment data from path \(path)")
        }
        
        //let parsed_path = path.replacingOccurrences(of: "._.", with: "/").replacingOccurrences(of: "../", with: "") ///Prevents LFI
		let parsed_path = path.replacingOccurrences(of: "../", with: "") /// To prevent LFI
        
        do {
            /// Pretty strsightforward -- get data and return it
            let attachment_data = try Data.init(contentsOf: URL(fileURLWithPath: ChatDelegate.imageStoragePrefix + parsed_path))
            return attachment_data
        } catch {
            self.log("WARNING: failed to load image for path \(ChatDelegate.imageStoragePrefix + path)")
            return Data.init(capacity: 0)
        }
    }
	
	func searchForString(term: String, case_sensitive: Bool = false, bridge_gaps: Bool = true) -> [String:[[String:String]]] {
        /// This gets all texts with $term in them; case_sensitive and bridge_gaps are customization options
        
        /// Create Connections
		var db = createConnection()
		var contact_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb")
        if db == nil || contact_db == nil { return [String:[[String:String]]]() }
		
        /// Replacing percentages with escaped so that they don't act as wildcard characters
        var upperTerm = term.replacingOccurrences(of: "%", with: "\\%")
        
        /// replace spaces with wildcard characters if bridge_gaps == true
		if bridge_gaps { upperTerm = upperTerm.split(separator: " ").joined(separator: "%") }
		
		var return_texts = [String:[[String:String]]]()
		
		let texts = selectFromSql(db: db, columns: ["ROWID", "text", "service", "date", "cache_has_attachments"], table: "message", condition: "WHERE text like \"%\(upperTerm)%\"")
		
		for var i in texts {
			if case_sensitive && !(i["text"]?.contains(term) ?? true) { continue } /// Sqlite3 library can't set like to be case-sensitive. Must manually check.
			
			if i["date"] != nil {
				let date: Int = Int(String(i["date"] ?? "0")) ?? 0
				let new_date: Int = date / 1000000000
				let timestamp: Int = new_date + 978307200
				i["date"] = String(timestamp) /// Turns it into unix timestamp for easier use
			}
			
            /// get sender for this text
			let handle = selectFromSql(db: db, columns: ["chat_identifier", "display_name"], table: "chat", condition: "WHERE ROWID in (SELECT chat_id from chat_message_join WHERE message_id is \(i["ROWID"] ?? ""))", num_items: 1)
			var chat = ""
			
			if handle.count > 0 {
				if handle[0]["display_name"]?.count == 0 {
					chat = handle[0]["chat_identifier"] ?? "(null)"
				} else {
					chat = "Group: " + (handle[0]["display_name"] ?? "(null)")
				}
			}
			
            /// Add this text onto the list of texts from this person that match term
			if return_texts[chat] == nil {
				return_texts[chat] = [i]
			} else {
				return_texts[chat]?.append(i)
			}
		}
		
        /// Replace Group name with list of recipients
		for i in Array(return_texts.keys) {
			if i.prefix(7) != "Group: " {
                let name = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: i)
				
				if name.count != 0 {
					return_texts[name] = return_texts[i]
					return_texts.removeValue(forKey: i)
				}
			}
		}
		
        /// close
		if sqlite3_close(db) != SQLITE_OK {
			self.log("WARNING: error closing database")
		}

		db = nil
		
		if sqlite3_close(contact_db) != SQLITE_OK {
			self.log("WARNING: error closing database")
		}

		contact_db = nil
		
		return return_texts
	}
	
	func getPhotoList(num: Int = 40, offset: Int = 0, most_recent: Bool = true) -> [[String: String]] { /// Gotta include stuff like favorite
		/// This gets a list of the $num (most_recent ? most recent : oldest) photos, offset by $offset.
		
        self.log("Getting list of photos, num: \(num), offset: \(offset), most recent: \(most_recent ? "true" : "false")")
        
        /// make sure that we have access to the photos library
		if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            var con = true;
            
            PHPhotoLibrary.requestAuthorization({ auth in
                if auth != PHAuthorizationStatus.authorized {
                    con = false
                    self.log("App is not authorized to view photos. Please grant access.")
                }
            })
            guard con else { return [[String:String]]() }
        }
        
        print("Has authorization")
		
		var ret_val = [[String:String]]()
		let fetchOptions = PHFetchOptions()
        
        /// sort photos by most recent
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: !most_recent)]
		fetchOptions.fetchLimit = num + offset
		
		let requestOptions = PHImageRequestOptions()
		requestOptions.isSynchronous = true
		requestOptions.isNetworkAccessAllowed = true
		
        /// get images!
		let result = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
		
		let total = result.countOfAssets(with: PHAssetMediaType.image)
        
        for i in offset..<total {
            var next = false;
			let dispatchGroup = DispatchGroup()
			
			var local_result = [String:String]()
            
			let image = result.object(at: i)
			var img_url = ""
			
			dispatchGroup.enter() /// This whole dispatchGroup this is necessary to get the completion handler to run synchronously with the rest
			
			image.getURL(completionHandler: { url in
                /// get url of each image
				img_url = url!.path.replacingOccurrences(of: "/var/mobile/Media/DCIM/", with: "")
				dispatchGroup.leave()
			})
			
			dispatchGroup.notify(queue: DispatchQueue.main) {
                /// append vals to return value
				local_result["URL"] = img_url
				local_result["is_favorite"] = String(image.isFavorite)
				
				ret_val.append(local_result)
                next = true
			}
            
            /// This is hacky and kinda hurts performance but it seems the most reliable way to load images in order + with the amount requested.
            while next == false {}
		}
        
		return ret_val
	}
	
	func getPhotoDatafromPath(path: String) -> Data {
		/// This returns the pure data of a photo at $path
		
		if self.debug {
			self.log("Getting photo data from path \(path)")
		}
		
		let parsed_path = path.replacingOccurrences(of: "\\/", with: "/").replacingOccurrences(of: "../", with: "") /// To prevent LFI
        
        /// get and return photo data
        let image = UIImage(contentsOfFile: ChatDelegate.photoStoragePrefix + parsed_path)
        /// Compress image to a jpeg with horrible quality since they're only thumbnails; don't think it actually improves web interface performance much tho
        let photo_data = image?.jpegData(compressionQuality: 0) ?? Data.init(capacity: 0)
        return photo_data
	}
}

extension PHAsset {

	func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        /// This allows for retrieval of a PHAsset's URL in the filesystem.
        
		if self.mediaType == .image {
			let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
			options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
				return true
			}
			self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
				completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
			})
		} else if self.mediaType == .video {
			let options: PHVideoRequestOptions = PHVideoRequestOptions()
			options.version = .original
			PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
				if let urlAsset = asset as? AVURLAsset {
					let localVideoUrl: URL = urlAsset.url as URL
					completionHandler(localVideoUrl)
				} else {
					completionHandler(nil)
				}
			})
		}
	}
}

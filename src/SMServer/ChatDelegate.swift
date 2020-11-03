import Foundation
import SQLite3
import SwiftUI
import Photos
import os

final class ChatDelegate {
	var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	let prefix: String = "SMServer_app: "

	static let addressBookAddress: String = "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb"
	static let imageStoragePrefix: String = "/private/var/mobile/Library/SMS/Attachments/"
	static let photoStoragePrefix: String = "/var/mobile/Media/"
	static let userHomeString: String = "/private/var/mobile/"

	final func log(_ s: String, warning: Bool = false) {
		/// Logs to syslog/console
		if self.debug || warning {
			os_log("%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, self.prefix, s)
		}
	}

	final func refreshVars() {
		self.debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	}

	final func createConnection(connection_string: String = "/private/var/mobile/Library/SMS/sms.db") -> OpaquePointer? {
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

		self.log("opened database")

		/// Return pointer to the database
		return db
	}

	final func closeDatabase(_ db: inout OpaquePointer?) {
		let close_code = sqlite3_close(db)
		if close_code != SQLITE_OK {
			self.log("WARNING: error closing database. Errror: \(close_code)", warning: true)
		}
		db = nil
	}

	final func selectFromSql(db: OpaquePointer?, columns: [String], table: String, condition: String = "", num_items: Int = -1, offset: Int = 0, split_ids: Bool = false) -> [[String:String]] {
		/// This executes an SQL query, specifically 'SELECT $columns from $table $condition LIMIT $offset, $num_items', on $db
		/// If you join tables, you may need to use stuff like `SELECT m.attr, h.otherattr from table m inner join othertable h;`.
		/// If you leave $split_ids as false, it will return the nested dicts with their original select columns, e.g. `m.attr` and `h.otherattr`
		/// However, if you set it to true, it will return them without the table identifier, e.g. `attr` and `otherattr`. Be conscious of that.

		/// Construct the query
		var sqlString = "SELECT " + columns.joined(separator: ", ")
		sqlString += " from " + table
		if condition != "" {
			sqlString += " " + condition
		}
		if num_items > 0 || offset != 0 {
			sqlString += " LIMIT \(offset), \(String(num_items))"
		}
		sqlString += ";"

		self.log("full sql query: " + sqlString)

		var statement: OpaquePointer?

		self.log("opened statement")

		/// Prepare the database for querying $sqlString
		if sqlite3_prepare_v2(db, sqlString, -1, &statement, nil) != SQLITE_OK {
			let errmsg = String(cString: sqlite3_errmsg(db)!)
			self.log("WARNING: error preparing select: \(errmsg)", warning: true)
		}

		var main_return = [[String:String]]()

		var i = 0
		/// for each row, up to num_items rows
		while sqlite3_step(statement) == SQLITE_ROW && (i < num_items || num_items <= 0) {
			var minor_return = [String:String]()
			/// for every column in the row
			for j in 0..<columns.count {
				var tiny_return = ""
				/// Get the string for the specific column
				if let tiny_return_cstring = sqlite3_column_text(statement, Int32(j)) {
					tiny_return = String(cString: tiny_return_cstring)
				}
				/// add it to return value
				let id = split_ids ? String(columns[j].split(separator: ".")[1]) : columns[j]
				minor_return[id] = tiny_return
			}
			/// Add it to return value
			main_return.append(minor_return)
			i += 1
		}

		/// Finalize; has to be done after getting info.
		if sqlite3_finalize(statement) != SQLITE_OK {
			let errmsg = String(cString: sqlite3_errmsg(db)!)
			self.log("WARNING: error finalizing prepared statement: \(errmsg)", warning: true)
		}

		statement = nil
		self.log("destroyed statement")

		/// Since we passed $db in as a parameter, we don't close the database here, but rather in the function where $db was constructed
		return main_return
	}

	final func getDisplayName(chat_id: String) -> String {
		/// This does the same thing as getDisplayName, but doesn't take db as an argument. This allows for fetching of a single name,
		/// when you don't need to get a lot of names at once.
		self.log("Getting display name for \(chat_id)")

		/// Connect to contact database
		var contact_db = createConnection(connection_string: ChatDelegate.addressBookAddress)
		var sms_db = createConnection()
		if contact_db == nil || sms_db == nil { return "" }

		/// get name
		let name = getDisplayNameWithDb(sms_db: sms_db, contact_db: contact_db, chat_id: chat_id)

		/// close
		closeDatabase(&sms_db)
		closeDatabase(&contact_db)

		self.log("destroyed dbs")

		return name
	}

	final func getDisplayNameWithDb(sms_db: OpaquePointer?, contact_db: OpaquePointer?, chat_id: String) -> String {
		/// Gets the first + last name of a contact with the phone number or email of $chat_id

		self.log("Getting display name for \(chat_id) with db")

		var display_name_array = [[String:String]]()

		/// Support for group chats
		if chat_id.prefix(4) == "chat" && !chat_id.contains("@") && chat_id.count > 20 {
			let check_name = selectFromSql(db: sms_db, columns: ["display_name"], table: "chat", condition: "where chat_identifier is \"\(chat_id)\"", num_items: 1)

			if check_name.count == 0 || check_name[0]["display_name"]?.count == 0 {
				let recipients = getGroupRecipientsWithDb(contact_db: contact_db, db: sms_db, ci: chat_id)

				return recipients.joined(separator: ", ")
			} else {
				return check_name[0]["display_name"]!
			}
		}

		if chat_id.contains("@") { /// if an email
			display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE \"%\(chat_id)%\"")
		} else if chat_id.contains("+") {
			display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id)%\"", num_items: 1)
		} else {
			display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE \"%\(chat_id) \" and c16Phone NOT LIKE \"%+%\"")
		}

		if display_name_array.count == 0 {
			let unc = selectFromSql(db: sms_db, columns: ["uncanonicalized_id"], table: "handle", condition: "WHERE id is \"\(chat_id)\"")

			guard unc.count > 0, let ret = unc[0]["uncanonicalized_id"] else {
				return ""
			}

			return ret
		}

		/// combine first name and last name
		let full_name: String = (display_name_array[0]["c0First"] ?? "no_first") + " " + (display_name_array[0]["c1Last"] ?? "no_last")

		self.log("full name for \(chat_id) is \(full_name)")

		return full_name
	}

	final func getGroupRecipientsWithDb(contact_db: OpaquePointer?, db: OpaquePointer?, ci: String) -> [String] {

		self.log("Getting group chat recipients for \(ci)")

		let recipients = selectFromSql(db: db, columns: ["id"], table: "handle", condition: "WHERE ROWID in (SELECT handle_id from chat_handle_join WHERE chat_id in (SELECT ROWID from chat where chat_identifier is \"\(ci)\"))")

		var ret_val = [String]()

		for i in recipients {

			/// get name for person
			let ds = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: i["id"] ?? "")
			ret_val.append((ds == "" ? i["id"] : ds) ?? "")
		}

		self.log("Finished retrieving recipients for \(ci)")

		return ret_val
	}

	final func loadMessages(num: String, num_items: Int, offset: Int = 0) -> [[String:String]] {
		/// This loads the latest $num_items messages from/to $num, offset by $offset.

		self.log("getting messages for \(num)")

		/// Create connection to text and contact databases
		var db = createConnection()
		var contact_db = createConnection(connection_string: ChatDelegate.addressBookAddress)
		if db == nil || contact_db == nil { return [[String:String]]() }

		/// check if it's a group chat
		let is_group = num.prefix(4) == "chat" && !num.contains("@")
		var messages = [[String:String]]()

		if is_group {
			messages = selectFromSql(db: db, columns: ["m.ROWID", "m.guid", "m.text", "m.subject", "m.is_from_me", "m.date", "m.service", "m.cache_has_attachments", "m.handle_id", "m.balloon_bundle_id", "m.associated_message_guid", "m.associated_message_type", "h.id"], table: "message m", condition: "left join handle h on h.ROWID = m.handle_id where m.ROWID in (select message_id from chat_message_join where chat_id in (select ROWID from chat where chat_identifier is \"\(num)\")) order by m.date desc", num_items: num_items, offset: offset, split_ids: true)
		} else {
			messages = selectFromSql(db: db, columns: ["ROWID", "guid", "text", "subject", "is_from_me", "date", "date_read", "service", "cache_has_attachments", "handle_id", "balloon_bundle_id", "associated_message_guid", "associated_message_type"], table: "message", condition: "WHERE ROWID IN (SELECT message_id FROM chat_message_join WHERE chat_id IN (SELECT ROWID from chat WHERE chat_identifier is \"\(num)\") ORDER BY message_date DESC) ORDER BY date DESC", num_items: num_items, offset: offset)
		}

		for i in 0..<messages.count {
			if messages[i]["cache_has_attachments"] == "1" && messages[i]["ROWID"] != nil {
				let a = getAttachmentFromMessage(mid: messages[i]["ROWID"] ?? "") /// get list of attachments
				var file_string = ""
				var type_string = ""
				for l in 0..<a.count {
					/// use ':' as separater between attachments 'cause you can't have a filename in iOS that contains it (I think?)
					/// Also yes I now recognize that this is terrible and I should just make this an array instead of a string.
					/// I'll fix that some time but this seems to function ok right now and I'm apprehensive to change the API
					file_string += a[l][0] + (l != a.count ? ":" : "")
					type_string += a[l][1] + (l != a.count ? ":" : "")
				}
				messages[i]["attachment_file"] = file_string
				messages[i]["attachment_type"] = type_string
			}

			if is_group && messages[i]["is_from_me"] == "0" && messages[i]["id"]?.count != 0 {
				let name = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: messages[i]["id"] ?? "")
				messages[i]["sender"] = name
			}

			if messages[i]["balloon_bundle_id"] == "com.apple.messages.URLBalloonProvider" && messages[i]["ROWID"] != nil {
				let link_info = getLinkInfo(messages[i]["ROWID"]!, db: db)

				messages[i]["link_title"] = link_info["title"]
				messages[i]["link_subtitle"] = link_info["subtitle"]
				messages[i]["link_type"] = link_info["type"]
			}
		}

		/// close dbs
		closeDatabase(&db)
		closeDatabase(&contact_db)

		self.log("destroyed db; returning messages")

		return messages
	}

	final func loadChats(num_to_load: Int, offset: Int = 0) -> [[String:String]] {
		/// This loads the most recent $num_to_load conversations, offset by $offset

		self.log("Getting \(String(num_to_load)) chats")

		var pinned_chats: [String] = [""]

		if offset == 0 && Float(UIDevice.current.systemVersion) ?? 13.0 >= 14.0 {
			DispatchQueue.global(qos: .default).async {
				let center = MRYIPCCenter.init(named: "com.ianwelker.smserver")
				pinned_chats = center?.callExternalMethod(Selector(("getPinnedChats")), withArguments: nil) as? [String] ?? [String]()
			}
		}

		/// Create connections
		var db = createConnection()
		var contacts_db = createConnection(connection_string: ChatDelegate.addressBookAddress)
		if db == nil || contacts_db == nil { return [[String:String]]() }

		let chats = selectFromSql(db: db, columns: ["m.ROWID", "m.is_read ", "m.is_from_me", "m.text", "m.item_type", "m.date_read", "m.date", "m.cache_has_attachments", "c.chat_identifier", "c.display_name", "c.room_name"], table: "chat_message_join j", condition: "inner join message m on j.message_id = m.ROWID inner join chat c on c.ROWID = j.chat_id where j.message_date in (select  max(j.message_date) from chat_message_join j inner join chat c on c.ROWID = j.chat_id group by c.chat_identifier) order by j.message_date desc", num_items: num_to_load, offset: offset)
		var return_array = [[String:String]]()

		let formatter = RelativeDateTimeFormatter()

		if offset == 0 && Float(UIDevice.current.systemVersion) ?? 13.0 >= 14.0 {
			DispatchQueue.main.sync {
				while pinned_chats == [""] {
					usleep(2000)
				}
			}
		}

		for i in chats {
			self.log("Beginning to iterate through chats for \(i["c.chat_identifier"]!)")

			var new_chat = [String:String]()

			/// Check for if it has unread. It has to fit all these specific things.
			new_chat["has_unread"] = (i["m.is_from_me"] == "0" && i["m.date_read"] == "0" && i["m.text"] != nil && i["m.is_read"] == "0" && i["m.item_type"] == "0") ? "true" : "false"

			/// Content of the most recent text. If a text has attachments, `i["m.text"]` will look like `\u{ef}`. this checks for that.
			new_chat["latest_text"] = ""
			if i["m.text"]?.replacingOccurrences(of: "\u{fffc}", with: "", options: NSString.CompareOptions.literal, range: nil).trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
				new_chat["latest_text"] = i["m.text"]
			} else if i["m.cache_has_attachments"] != "0" {
				let att = getAttachmentFromMessage(mid: i["m.ROWID"] ?? "")

				/// Make it say like `Attachment: Image` if there's no text
				if att.count != 0 && att[0].count == 2 {
					new_chat["latest_text"] = "Attachment: " + att[0][1].prefix(upTo: att[0][1].firstIndex(of: "/") ?? att[0][1].endIndex)
				}
			}

			/// Get name for chat
			if i["c.display_name"]!.count == 0 {
				new_chat["display_name"] = getDisplayNameWithDb(sms_db: db, contact_db: contacts_db, chat_id: i["c.chat_identifier"]!)
			} else {
				new_chat["display_name"] = i["c.display_name"]
			}

			/// Cause `i["h.id"]` is just the `chat_identifier` of one of the members of the group if it's a group chat.
			new_chat["chat_identifier"] = i["c.chat_identifier"]
			new_chat["time_marker"] = i["m.date"]
			new_chat["pinned"] = "false"

			for c in 0..<pinned_chats.count {
				if i["c.chat_identifier"] == pinned_chats[c] {
					new_chat["pinned"] = "true"
					pinned_chats.remove(at: c)
					break
				}
			}

			let t: Double = ((Double(i["m.date"] ?? "0") ?? 0.0) / 1000000000.0) + 978307200.0
			let d = Date(timeIntervalSince1970: t)

			new_chat["relative_time"] = formatter.localizedString(for: d, relativeTo: Date())

			return_array.append(new_chat)
		}

		/// Just in case your pinned chats aren't in your most recent texts
		if offset == 0 && pinned_chats != [""] {
			for i in pinned_chats {
				var new_chat = [String:String]()
				new_chat["pinned"] = "true"
				new_chat["display_name"] = getDisplayNameWithDb(sms_db: db, contact_db: contacts_db, chat_id: i)

				return_array.append(new_chat)
			}
		}

		/// close
		closeDatabase(&contacts_db)
		closeDatabase(&db)

		self.log("destroyed db")

		return return_array
	}

	final func returnImageData(chat_id: String) -> Data {
		/// This does the same thing as returnImageDataDB, but without the contact_db and image_db as arguments, if you just need to get like 1 image

		self.log("Getting image data for chat_id \(chat_id)")

		/// Make connections
		var contact_db = createConnection(connection_string: ChatDelegate.addressBookAddress)
		var image_db = createConnection(connection_string: "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb")
		if contact_db == nil || image_db == nil { return Data.init(capacity: 0) }

		/// get image data with dbs as parameters
		let return_val = returnImageDataDB(chat_id: chat_id, contact_db: contact_db!, image_db: image_db!)

		/// close
		closeDatabase(&contact_db)
		closeDatabase(&image_db)

		return return_val
	}

	final func returnImageDataDB(chat_id: String, contact_db: OpaquePointer, image_db: OpaquePointer) -> Data {
		/// This returns the profile picture for someone with the phone number or email $chat_id as pure image data

		self.log("Getting image data with db for chat_id \(chat_id)")

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

		self.log("opened statement")

		if sqlite3_prepare_v2(image_db, sqlString, -1, &statement, nil) != SQLITE_OK {
			let errmsg = String(cString: sqlite3_errmsg(image_db)!)
			self.log("WARNING: error preparing select: \(errmsg)", warning: true)
		}

		var pngdata: Data

		if sqlite3_step(statement) == SQLITE_ROW {
			if let tiny_return_blob = sqlite3_column_blob(statement, 0) {

				/// Getting the data
				let len: Int32 = sqlite3_column_bytes(statement, 0)
				let dat: NSData = NSData(bytes: tiny_return_blob, length: Int(len))

				pngdata = dat as Data

			} else {
				self.log("No profile picture found. Using default.")

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
			self.log("WARNING: error finalizing prepared statement: \(errmsg)", warning: true)
		}

		statement = nil
		self.log("destroyed statement")

		return pngdata
	}

	final func getAttachmentFromMessage(mid: String) -> [[String]] {
		/// This returns the file path for all attachments associated with a certain message with the message_id of $mid

		self.log("Gettig attachment for mid \(mid)")

		/// create connection, get attachments information
		var db = createConnection()
		if db == nil { return [[String]]() }

		let file = selectFromSql(db: db, columns: ["filename", "mime_type", "hide_attachment"], table: "attachment", condition: "WHERE ROWID in (SELECT attachment_id from message_attachment_join WHERE message_id is \(mid))")

		var return_val = [[String]]()
		self.log("attachment file length: \(String(file.count))")

		if file.count > 0 {
			for i in file {

				/// get the path of the attachment minus the attachment storage prefix ("/private/var/mobile/Library/SMS/Attachments/")
				let suffixed = String(i["filename"]?.dropFirst(ChatDelegate.imageStoragePrefix.count - ChatDelegate.userHomeString.count + 2) ?? "")
				let type = i["mime_type"] ?? ""

				/// Append to return array
				return_val.append([suffixed, type])
			}
		}

		closeDatabase(&db)

		return return_val
	}

	final func getAttachmentType(path: String) -> String {
		/// This gets the file type of the attachment at $path

		self.log("Getting attachment type for @ \(path)")

		var db = createConnection()
		if db == nil { return "" }

		let file_type_array = selectFromSql(db: db, columns: ["mime_type"], table: "attachment", condition: "WHERE filename like \"%\(path)%\"", num_items: 1)
		var return_val = "image/jpeg" /// Most likely thing

		if file_type_array.count > 0 {
			return_val = file_type_array[0]["mime_type"]!
		}

		closeDatabase(&db)

		return return_val
	}

	final func getAttachmentDataFromPath(path: String) -> Data {
		/// This returns the pure data of a file (attachment) at $path

		self.log("Getting attachment data from path \(path)")

		let parsed_path = path.replacingOccurrences(of: "../", with: "") /// To prevent LFI

		do {
			/// Pretty strsightforward -- get data and return it
			let attachment_data = try Data.init(contentsOf: URL(fileURLWithPath: ChatDelegate.imageStoragePrefix + parsed_path))
			return attachment_data
		} catch {
			self.log("WARNING: failed to load image for path \(ChatDelegate.imageStoragePrefix + path)", warning: true)
			return Data.init(capacity: 0)
		}
	}

	final func searchForString(term: String, case_sensitive: Bool = false, bridge_gaps: Bool = true, group_by_time: Bool = true) -> Any {
		/// This gets all texts with $term in them; case_sensitive, bridge_gaps, and group_by_time are customization options

		/// Create Connections
		var db = createConnection()
		var contact_db = createConnection(connection_string: ChatDelegate.addressBookAddress)
		if db == nil || contact_db == nil { return [String:[[String:String]]]() }

		/// Replacing percentages with escaped so that they don't act as wildcard characters
		var upperTerm = term.replacingOccurrences(of: "%", with: "\\%")

		/// replace spaces with wildcard characters if bridge_gaps == true
		if bridge_gaps { upperTerm = upperTerm.split(separator: " ").joined(separator: "%") }

		var return_texts = [String:[[String:String]]]()
		var names = [String:String]()

		var texts = selectFromSql(db: db, columns: ["c.chat_identifier", "c.display_name", "m.ROWID", "m.text", "m.service", "m.date", "m.cache_has_attachments"], table: "message m", condition: "inner join chat_message_join j on j.message_id = m.ROWID inner join chat c on j.chat_id = c.ROWID WHERE text like \"%\(upperTerm)\" order by m.date desc", split_ids: true)

		/// If case sensitive, remove those who don't exactly match. sqlite select is hardcoded case insensitive
		if case_sensitive { texts.removeAll(where: { !($0["text"]?.contains(term) ?? true) })}

		for var i in texts {

			/// get sender for this text
			let chat = i["chat_identifier"] ?? "(null)"

			if i["display_name"]?.count == 0 {
				if names[i["chat_identifier"] ?? ""] == nil {
					let name = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: i["chat_identifier"] ?? "")
					names[i["chat_identifier"] ?? ""] = name
					i["display_name"] = name
				} else {
					i["display_name"] = names[i["chat_identifier"] ?? ""]
				}
			}

			/// Add this text onto the list of texts from this person that match term if grouping by person and not time
			if !group_by_time {
				if return_texts[chat] == nil {
					return_texts[chat] = [i]
				} else {
					return_texts[chat]?.append(i)
				}
			}
		}

		/// close
		closeDatabase(&db)
		closeDatabase(&contact_db)

		return group_by_time ? texts : return_texts
	}

	final func getPhotoList(num: Int = 40, offset: Int = 0, most_recent: Bool = true) -> [[String: String]] {
		/// This gets a list of the $num (most_recent ? most recent : oldest) photos, offset by $offset.
		self.log("Getting list of photos, num: \(num), offset: \(offset), most recent: \(most_recent ? "true" : "false")")

		/// make sure that we have access to the photos library
		if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
			var con = true;

			PHPhotoLibrary.requestAuthorization({ auth in
				if auth != PHAuthorizationStatus.authorized {
					con = false
					self.log("App is not authorized to view photos. Please grant access.", warning: true)
				}
			})
			guard con else { return [[String:String]]() }
		}

		var ret_val = [[String:String]]()
		let fetchOptions = PHFetchOptions()

		/// sort photos by most recent
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: !most_recent)]
		fetchOptions.fetchLimit = num + offset

		/// get images!
		let result = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
		let total = result.countOfAssets(with: PHAssetMediaType.image)

		for i in offset..<total {

			var local_result = [String:String]()

			let image = result.object(at: i)
			var img_url = ""

			image.getURL(completionHandler: { url in
				/// get url of each image
				if url != nil {
					img_url = url!.path.replacingOccurrences(of: ChatDelegate.photoStoragePrefix, with: "")
				} else {
					img_url = "nil" /// Cause it has to be something to continue
				}
			})

			/// This is hacky and kinda hurts performance but it seems the most reliable way to load images in order + with the amount requested.
			while img_url == "" {}

			/// append vals to return value
			local_result["URL"] = img_url
			local_result["is_favorite"] = String(image.isFavorite)

			ret_val.append(local_result)
		}

		return ret_val
	}

	final func getPhotoDatafromPath(path: String) -> Data {
		/// This returns the pure data of a photo at $path

		self.log("Getting photo data from path \(path)")

		/// To prevent LFI
		let parsed_path = path.replacingOccurrences(of: "\\/", with: "/").replacingOccurrences(of: "../", with: "")

		/// get and return photo data
		let image = UIImage(contentsOfFile: ChatDelegate.photoStoragePrefix + parsed_path)

		/// Compress image to a jpeg with horrible quality since they're only thumbnails
		let photo_data = image?.jpegData(compressionQuality: 0) ?? Data.init(capacity: 0)
		return photo_data
	}

	final func getLinkInfo(_ mid: String, db: OpaquePointer?) -> [String:String] {
		/// This get a Rich Link's title text from the sql database. Was quite the pain to get working.
		/// I'll expland it in the future to get like the subtitle and other stuff too
		let sqlString = "SELECT payload_data from message where ROWID is \(mid);"

		var statement: OpaquePointer?
		var ret_dict = ["title": "Title", "subtitle": "Subtitle", "type": "Website"]

		self.log("Opened statement in getLinkTitle")

		/// Prepare sql statement
		var ret_code = sqlite3_prepare_v2(db, sqlString, -1, &statement, nil)
		if ret_code != SQLITE_OK {
			self.log("WARNING: error preparing select: \(ret_code)", warning: true)
		}

		var data: NSData = NSData.init()

		/// Get blob data
		if sqlite3_step(statement) == SQLITE_ROW {
			if let tiny_return_blob = sqlite3_column_blob(statement, 0) {
				let len: Int32 = sqlite3_column_bytes(statement, 0)
				data = NSData(bytes: tiny_return_blob, length: Int(len))
			}
		}

		/// finalize sqlite statement
		ret_code = sqlite3_finalize(statement)
		if ret_code != SQLITE_OK {
			self.log("WARNING: error finalizing statement: \(ret_code)", warning: true)
		}

		/// Blob data is technically an NSKeyedArchiver plist file. We just gotta serialize it and extract values
		var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
		var plistData = [String:AnyObject]()
		do {
			plistData = try PropertyListSerialization.propertyList(from: data as Data, options: .mutableContainersAndLeaves, format: &propertyListFormat) as! [String : AnyObject]
		} catch {
			self.log("WARNING: failed to decode plist", warning: true)
			return ret_dict
		}

		statement = nil

		/// Always under object `$objects`
		let objects: [Any] = plistData["$objects"] as! [Any]

		if let title: String = objects[6] as? String {
			ret_dict["title"] = title
			let subtitle = objects[4] as? String ?? "//website/"
			ret_dict["subtitle"] = String(subtitle.split(separator: "/")[1])
			ret_dict["type"] = objects[9] as? String ?? "website"
		} else if objects.count > 9 {
			ret_dict["title"] = objects[8] as? String ?? "No Title Available"
			ret_dict["subtitle"] = objects[9] as? String ?? "No subtitle available"
		}

		return ret_dict
	}
}

extension PHAsset {

	final func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
		/// This allows for retrieval of a PHAsset's URL in the filesystem.

		if self.mediaType == .image {
			let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
			options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
				return true
			}
			self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
				completionHandler(contentEditingInput?.fullSizeImageURL as URL?)
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

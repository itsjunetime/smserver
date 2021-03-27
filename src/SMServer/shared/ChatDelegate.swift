import Foundation
import SQLite3
import SwiftUI
import Photos

#if os(macOS)
import Contacts
#endif

final class ChatDelegate {
	let settings = Settings.shared()

	final func createConnection(connection_string: String = Const.sms_db_address) -> OpaquePointer? {
		/// This simply returns an opaque pointer to the database at `connection_string`, allowing for sqlite connections.
		var db: OpaquePointer?

		/// Open the database
		let return_code = sqlite3_open_v2(connection_string, &db, SQLITE_OPEN_READONLY, nil)

		if return_code != SQLITE_OK {
			Const.log("WARNING: error opening database at \(connection_string): \(return_code)")
			sqlite3_close(db)
			db = nil
			return db
		}

		sqlite3_busy_timeout(db, 20)

		Const.log("opened database")

		/// Return pointer to the database
		return db
	}

	final func closeDatabase(_ db: inout OpaquePointer?) {
		let close_code = sqlite3_close(db)
		if close_code != SQLITE_OK {
			Const.log("WARNING: error closing database. Errror: \(close_code)", warning: true)
		}
		db = nil
	}

	/// It's just too big to do one line
	final func selectFromSql(
		db: OpaquePointer?,
		columns: [String],
		table: String,
		condition: String = "",
		args: [Any] = [Any](),
		num_items: Int = -1,
		offset: Int = 0,
		split_ids: Bool = false
	) -> [[String:String]] {
		/// This executes an SQL query, basically 'SELECT `column` from `table` `condition` LIMIT `offset`, `num_items`', on `db`
		/// If you join tables, you may need to use stuff like `SELECT m.attr, h.otherattr from table m inner join othertable h;`.
		/// If you leave `split_ids` as false, it will return the nested dicts with their original select columns, e.g. `m.attr` and `h.otherattr`
		/// However, if you set it to true, it will return them without the table identifier, e.g. `attr` and `otherattr`. Be conscious of that.

		/// You also must be very careful of inserting values into the condition: For every place that you want to insert a String or Int into the
		/// condition (e.g. `LIKE "STRING"`), you need to place a `?` in the `condition` string, and place the Strings/Ints that need to replace them
		/// into the `args` array.
		/// For example, to do `... WHERE text LIKE "HELLO" AND ROWID IS 4`, you'll want `condition == "... WHERE text like ? AND ROWID IS ?`
		/// and `args == ["HELLO", 4]`. This will allow them to be sanitized and inserted correctly.

		/// Construct the query
		var sqlString = "SELECT \(columns.joined(separator: ", ")) from \(table)"
		if condition != "" {
			sqlString += " \(condition)"
		}
		if num_items > 0 || offset != 0 {
			sqlString += " LIMIT \(offset), \(num_items)"
		}
		sqlString += ";"

		Const.log("full sql query: \(sqlString)")

		var statement: OpaquePointer?

		Const.log("opened statement")

		var main_return = [[String:String]]()

		/// Prepare the database for querying `sqlString`
		if sqlite3_prepare_v2(db, sqlString, -1, &statement, nil) != SQLITE_OK {
			let errmsg = String(cString: sqlite3_errmsg(db)!)
			Const.log("WARNING: error preparing select: \(errmsg)", warning: true)
			return main_return
		}

		for i in 0..<args.count {
			let arg = args[i]
			if arg is Int {
				sqlite3_bind_int(statement, Int32(i + 1), Int32(arg as! Int))
			} else if arg is String {
				sqlite3_bind_text(statement, Int32(i + 1), NSString(string: arg as! String).utf8String, -1, nil)
			}
		}

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
			Const.log("WARNING: error finalizing prepared statement: \(errmsg)", warning: true)
		}

		statement = nil
		Const.log("destroyed statement")

		/// Since we passed `db` in as a parameter, we don't close the database here, but rather in the function where `db` was constructed
		return main_return
	}

	final func parseTexts(_ texts: inout [[String:Any]], db: OpaquePointer?, contact_db: OpaquePointer?, is_group: Bool = false) {
		Const.log("parsing texts with length \(texts.count)")

		var names = [String:String]() /// key: id, val: display name.
		let bad_bundles = ["com.apple.DigitalTouchBalloonProvider", "com.apple.Handwriting.HandwritingProvider"]

		for i in 0..<texts.count {
			texts[i]["text"] = (texts[i]["text"] as? String ?? "").replacingOccurrences(of: "\u{fffc}", with: "", options: NSString.CompareOptions.literal, range: nil)

			/// Get details about attachments if there are any attachments associated with this message
			if texts[i]["cache_has_attachments"] as! String == "1" && texts[i]["ROWID"] != nil {
				let att = getAttachmentFromMessage(mid: (texts[i]["ROWID"] as? String ?? "")) /// get list of attachments
				texts[i]["attachments"] = att
			}

			/// Get the sender's name for this text if it is a group chat and it's not from me
			if is_group && texts[i]["is_from_me"] as? String ?? "0" == "0" && (texts[i]["id"] as? String)?.count != 0 {
				if names[texts[i]["id"] as! String] != nil {
					texts[i]["sender"] = names[texts[i]["id"] as! String]
				} else {
					let name = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: (texts[i]["id"] as? String) ?? "", is_group: is_group)
					texts[i]["sender"] = name
					names[texts[i]["id"] as! String] = name
				}
			}

			/// This checks if it has anything in the `payload_data` field, which would imply that it is a special message (e.g. rich link, gamepigeon message, etc).
			/// However, it doesn't enter the `if` if the message is a handwritten message or a digital touch message, since I don't know how to parse those yet.
			if (texts[i]["payload_data"] as? String)?.count ?? 0 > 0 && !bad_bundles.contains(texts[i]["balloon_bundle_id"] as! String) && texts[i]["ROWID"] != nil {
				let link_info = getLinkInfo(texts[i]["ROWID"] as? String ?? "", db: db)

				texts[i]["link_title"] = link_info["title"]
				texts[i]["link_subtitle"] = link_info["subtitle"]
				texts[i]["link_type"] = link_info["type"]
			}

			texts[i].removeValue(forKey: "payload_data")

			/// Change values that shouldn't be strings to the correct type
			if texts[i]["ROWID"] != nil                    { texts[i]["ROWID"] = Int(texts[i]["ROWID"] as! String) }
			if texts[i]["is_from_me"] != nil               { texts[i]["is_from_me"] = texts[i]["is_from_me"] as! String == "1" }
			if texts[i]["date"] != nil                     { texts[i]["date"] = Int(texts[i]["date"] as! String) }
			if texts[i]["date_read"] != nil                { texts[i]["date_read"] = Int(texts[i]["date_read"] as! String) }
			if texts[i]["cache_has_attachments"] != nil    { texts[i]["cache_has_attachments"] = texts[i]["cache_has_attachments"] as! String == "1" }
			if texts[i]["associated_message_type"] != nil  { texts[i]["associated_message_type"] = Int(texts[i]["associated_message_type"] as! String) }
			if texts[i]["item_type"] != nil                { texts[i]["item_type"] = Int(texts[i]["item_type"] as! String) }
			if texts[i]["group_action_type"] != nil        { texts[i]["group_action_type"] = Int(texts[i]["group_action_type"] as! String) ?? 0 }
		}
	}

	final func getDisplayName(chat_id: String, is_group: Bool? = nil) -> String {
		/// This does the same thing as getDisplayName, but doesn't take db as an argument. This allows for fetching of a single name,
		/// when you don't need to get a lot of names at once.
		Const.log("Getting display name for \(chat_id)")

		/// Connect to contact database
		var contact_db = createConnection(connection_string: Const.contacts_address)
		var sms_db = createConnection()
		if contact_db == nil || sms_db == nil { return "" }

		/// get name
		let name = getDisplayNameWithDb(sms_db: sms_db, contact_db: contact_db, chat_id: chat_id, is_group: is_group)

		/// close
		closeDatabase(&sms_db)
		closeDatabase(&contact_db)

		Const.log("destroyed dbs")

		return name
	}

	final func getDisplayNameWithDb(sms_db: OpaquePointer?, contact_db: OpaquePointer?, chat_id: String, is_group: Bool? = nil) -> String {
		/// Gets the first + last name of a contact with the phone number or email of `chat_id`

		Const.log("Getting display name for \(chat_id) with db")

		/// Support for group chats
		if is_group == nil || is_group ?? false {
			let check_name = selectFromSql(db: sms_db, columns: ["room_name", "display_name"], table: "chat", condition: "where chat_identifier is ?", args: [chat_id], num_items: 1)

			if check_name.count > 0 && check_name[0]["room_name"]?.count ?? 0 > 0 {
				if check_name.count == 0 || check_name[0]["display_name"]?.count == 0 {
					let recipients = getGroupRecipientsWithDb(contact_db: contact_db, db: sms_db, ci: chat_id)

					return recipients.joined(separator: ", ")
				} else {
					return check_name[0]["display_name"]!
				}
			}
		}

		/// For iOS, I extract info from the Address book database. I could use the Contacts framework, but it adds ~0.5 seconds per ~40 chats.
		/// So this is is a bit more code, but it is significantly faster, and I have yet to come to a circumstance where it's less accurate.
		/// I think it's definitely worth it.
		#if os(iOS)

		var display_name_array = [[String:String]]()

		if chat_id.contains("@") { /// if an email
			display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE ?", args: ["%\(chat_id)%"])
		} else if chat_id.contains("+") {
			display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE ?", args: ["%\(chat_id)%"], num_items: 1)
		} else {
			display_name_array = selectFromSql(db: contact_db, columns: ["c0First", "c1Last"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE ? and c16Phone NOT LIKE \"%+%\"", args: ["%\(chat_id) "])
		}

		if display_name_array.count == 0 {
			let unc = selectFromSql(db: sms_db, columns: ["uncanonicalized_id"], table: "handle", condition: "WHERE id is ?", args: [chat_id])

			guard unc.count > 0, let ret = unc[0]["uncanonicalized_id"] else {
				return chat_id
			}

			return ret.count == 0 ? chat_id : ret
		}

		/// combine first name and last name
		let full_name: String = "\(display_name_array[0]["c0First"] ?? "no_first") \(display_name_array[0]["c1Last"] ?? "no_last")"

		#elseif os(macOS)

		let pred = chat_id.contains("@") ? CNContact.predicateForContacts(matchingEmailAddress: chat_id) : CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: chat_id))
		let keys: [CNKeyDescriptor] = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey] as! [CNKeyDescriptor]
		let store = CNContactStore()
		var con_access = true

		let dp_group = DispatchGroup()
		dp_group.enter()

		store.requestAccess(for: CNEntityType.contacts, completionHandler: { accepted, _ in
			con_access = accepted
			dp_group.leave()
		})

		dp_group.wait()

		var full_name = chat_id

		if con_access {
			do {
				let contacts = try store.unifiedContacts(matching: pred, keysToFetch: keys)
				if contacts.count > 0 {
					full_name = "\(contacts[0].givenName) \(contacts[0].familyName)"
				}
			} catch {
				print("no... :(") /// will fix
			}
		}

		#endif

		Const.log("full name for \(chat_id) is \(full_name)")

		return full_name
	}

	final func getGroupRecipientsWithDb(contact_db: OpaquePointer?, db: OpaquePointer?, ci: String) -> [String] {

		Const.log("Getting group chat recipients for \(ci)")

		let recipients = selectFromSql(db: db, columns: ["id"], table: "handle", condition: "WHERE ROWID in (SELECT handle_id from chat_handle_join WHERE chat_id in (SELECT ROWID from chat where chat_identifier is ?))", args: [ci])

		var ret_val = [String]()

		for i in recipients {

			/// get name for person
			let ds = getDisplayNameWithDb(sms_db: db, contact_db: contact_db, chat_id: i["id"] ?? "", is_group: false)
			ret_val.append((ds == "" ? i["id"] : ds) ?? "")
		}

		Const.log("Finished retrieving recipients for \(ci)")

		return ret_val
	}

	final func loadMessages(num: String, num_items: Int, offset: Int = 0, from: Int = 0, surrounding: Int? = nil) -> [[String:Any]] {
		/// This loads the latest `num_items` messages from/to `num`, offset by `offset`.

		Const.log("getting messages for \(num)")

		/// Create connection to text and contact databases
		var db = createConnection()
		var contact_db = createConnection(connection_string: Const.contacts_address)
		if db == nil || contact_db == nil { return [[String:String]]() }

		/// check if it's a group chat
		let is_group = num.prefix(4) == "chat" && !num.contains("@") && num.count >= 20
		var from_string: String = ""
		var fixed_num = "?"

		if num.contains(",") {
			/// So that you can merge multiple conversations
			fixed_num = [String](repeating: "?", count: num.split(separator: ",").count).joined(separator: " or chat_identifier is ")
		}

		if from != 0 {
			from_string = " and m.is_from_me is \(from == 1 ? 1 : 0)"
		}

		var messages: [[String:Any]] = selectFromSql(
			db: db,
			columns: ["m.ROWID", "m.guid", "m.text", "m.subject", "m.is_from_me", "m.date", "m.date_read", "m.service", "m.cache_has_attachments", "m.balloon_bundle_id", "m.payload_data", "m.associated_message_guid", "m.associated_message_type", "m.item_type", "m.group_action_type", "h.id"],
			table: "message m",
			condition: "left join handle h on h.ROWID = m.handle_id where m.ROWID in (select message_id from chat_message_join where chat_id in (select ROWID from chat where chat_identifier is \(fixed_num)\(from_string))) order by m.date desc",
			args: num.split(separator: ",").map({String($0)}),
			num_items: num_items,
			offset: offset,
			split_ids: true
		)

		parseTexts(&messages, db: db, contact_db: contact_db, is_group: is_group)

		/// close dbs
		closeDatabase(&db)
		closeDatabase(&contact_db)

		Const.log("destroyed db; returning messages")

		return messages
	}

	final func loadChats(num_to_load: Int, offset: Int = 0) -> [[String:Any]] {
		/// This loads the most recent `num_to_load` conversations, offset by `offset`

		Const.log("Getting \(String(num_to_load)) chats")

		var pinned_chats: [String]? = nil
		var return_array = [[String:Any]]()
		let dp_group = DispatchGroup()

		if offset == 0 {
			#if os(iOS)
			if Const.getOSVersion() >= 14.0 {
				DispatchQueue.global(qos: .default).async {
					dp_group.enter()
					let center = MRYIPCCenter(named: "com.ianwelker.smserver")
					pinned_chats = center?.callExternalMethod(#selector(SMServerIPC.getPinnedChats), withArguments: nil) as? [String] ?? [String]()
					dp_group.leave()
				}
			}
			#elseif os(macOS)
			if Const.getOSVersion() >= 10.15 {
				pinned_chats = [String]() /// TEMPORARY. Will fix.
			}
			#endif
		}

		/// Create connections
		var db = createConnection()
		var contacts_db = createConnection(connection_string: Const.contacts_address)
		if db == nil || contacts_db == nil { return return_array }

		var addresses = [[String:String]]()
		var chat_identifiers = [String:[String]]()
		var checked = [String]()

		let chats: [[String:Any]] = selectFromSql(
			db: db,
			columns: ["m.ROWID", "m.is_read", "m.is_from_me", "m.text", "m.item_type", "m.date_read", "m.date", "m.cache_has_attachments", "m.balloon_bundle_id", "c.chat_identifier", "c.display_name", "c.room_name"], table: "chat_message_join j",
			condition: "inner join message m on j.message_id = m.ROWID inner join chat c on c.ROWID = j.chat_id where j.message_date in (select  max(j.message_date) from chat_message_join j inner join chat c on c.ROWID = j.chat_id group by c.chat_identifier) order by j.message_date desc",
			num_items: num_to_load,
			offset: offset
		)

		inner: if settings.combine_contacts {
			/// This `if` gets all the addresses associated with your contacts, parses them with regex to get all possible `chat_identifier`s,
			/// then puts them into a nested array. Later on, the conversations check themselves with the nested arrays to find the associated `chat_identifier`s.
			/// This section is probably not very optimized and probably also inaccurate. That's why it's optional.

			addresses = selectFromSql(db: contacts_db, columns: ["c16Phone", "c17Email"], table: "ABPersonFullTextSearch_content")
			let identifiers = selectFromSql(db: db, columns: ["chat_identifier"], table: "chat").map({$0["chat_identifier"] ?? ""})

			for i in addresses {
				var personal_addresses = i["c17Email"]?.split(separator: " ").map({String($0)}) ?? [String]()
				let phone = i["c16Phone"] ?? ""

				var checked_matches = personal_addresses
				personal_addresses += phone.split(separator: " ").map({String($0)})

				outerfor: for j in personal_addresses {
					let len = (j.filter { "0"..."9" ~= $0}).count
					if !(j.count >= 5 && (len == j.count || (len == j.count - 1 && j.first == "+"))) {
						continue outerfor
					}
					for l in checked_matches {
						if (l.contains(j)) {
							continue outerfor
						}
					}
					if identifiers.contains(j) {
						checked_matches.append(j)
					}
				}

				for j in checked_matches {
					chat_identifiers[j] = checked_matches
				}
			}
		}

		dp_group.wait()

		for i in chats {
			Const.log("Beginning to iterate through chats for \(i["c.chat_identifier"] as! String)")

			var new_chat = [String:Any]()

			if settings.combine_contacts {
				if checked.contains(i["c.chat_identifier"] as! String) { continue }

				let these_addresses: [String] = chat_identifiers[i["c.chat_identifier"] as! String] ?? [String]()
				new_chat["addresses"] = these_addresses.joined(separator: ",")
				for j in these_addresses {
					checked.append(j)
				}
			} else {
				new_chat["addresses"] = i["c.chat_identifier"] as? String
			}

			/// Check for if it has unread. It has to fit all these specific things.
			new_chat["has_unread"] = i["m.is_from_me"] as! String == "0" && i["m.date_read"] as! String == "0" && i["m.text"] != nil && i["m.is_read"] as! String == "0" && i["m.item_type"] as! String == "0"

			/// Content of the most recent text. If a text has attachments, `i["m.text"]` will look like `\u{ef}`. this checks for that.
			new_chat["latest_text"] = String((i["m.text"] as! String).replacingOccurrences(of: "\u{fffc}", with: "", options: NSString.CompareOptions.literal, range: nil))

			if (new_chat["latest_text"] as! String).count == 0 && i["m.cache_has_attachments"] as! String != "0" {
				let att = getAttachmentFromMessage(mid: i["m.ROWID"] as! String)

				/// Make it say like `Attachment: Image` if there's no text
				if att.count != 0 && att[0].count == 2 && att[0]["mime_type"]?.count ?? 0 > 0 {
					new_chat["latest_text"] = "Attachment: \(att[0]["mime_type"]?.split(separator: "/").first ?? "1 File")"
				} else {
					new_chat["latest_text"] = "Attachment: 1 File"
				}
			} else if i["m.balloon_bundle_id"] as! String == "com.apple.DigitalTouchBalloonProvder" {
				new_chat["latest_text"] = "Digital Touch Message"
			} else if i["m.balloon_bundle_id"] as! String == "com.apple.Handwriting.HandwritingProvider" {
				new_chat["latest_text"] = "Handwritten Message"
			}

			/// Get name for chat
			if (i["c.display_name"] as! String).count == 0 {
				new_chat["display_name"] = getDisplayNameWithDb(sms_db: db, contact_db: contacts_db, chat_id: i["c.chat_identifier"] as! String, is_group: (i["c.room_name"] as! String).count > 0)
			} else {
				new_chat["display_name"] = i["c.display_name"]
			}

			if let pins = pinned_chats {
				new_chat["pinned"] = pins.contains(i["c.chat_identifier"] as! String)
				pinned_chats!.removeAll(where: { $0 == i["c.chat_identifier"] as! String })
			} else {
				new_chat["pinned"] = false
			}

			new_chat["relative_time"] = Const.getRelativeTime(ts: Double(i["m.date"] as! String) ?? 0.0)

			new_chat["is_group"] = (i["c.room_name"] as! String) != ""
			new_chat["chat_identifier"] = i["c.chat_identifier"]
			new_chat["time_marker"] = Int(i["m.date"] as! String)

			return_array.append(new_chat)
		}

		/// Just in case your pinned chats aren't in your most recent texts
		if offset == 0, let pins = pinned_chats {
			for chat in pins {
				var new_chat = [String:Any]()
				new_chat["pinned"] = true
				new_chat["display_name"] = getDisplayNameWithDb(sms_db: db, contact_db: contacts_db, chat_id: chat)
				new_chat["chat_identifier"] = chat

				return_array.append(new_chat)
			}
		}

		/// close
		closeDatabase(&contacts_db)
		closeDatabase(&db)

		Const.log("destroyed db")

		return return_array
	}

	final func returnImageData(chat_id: String) -> Data {
		/// This does the same thing as returnImageDataDB, but without the `contact_db` and `image_db` as arguments, if you just need to get like 1 image

		Const.log("Getting image data for chat_id \(chat_id)")

		/// Make connections
		var contact_db = createConnection(connection_string: Const.contacts_address)

		#if os(iOS)
		var image_db = createConnection(connection_string: Const.contact_images_address)
		var sms_db = createConnection()
		if contact_db == nil || image_db == nil || sms_db == nil {
			return Data()
		}

		/// get image data with dbs as parameters
		let return_val = returnImageDataDB(chat_id: chat_id, contact_db: contact_db!, image_db: image_db!, sms_db: sms_db!)

		/// close
		closeDatabase(&image_db)
		closeDatabase(&sms_db)

		#elseif os(macOS)
		let image_name = selectFromSql(db: contact_db, columns: ["ZUNIQUEID"], table: "ZABCDRECORD", condition: "WHERE ZCONTACTINDEX IN (SELECT Z_PK from ZABCDCONTACTINDEX WHERE ZSTRINGFORINDEXING LIKE ?)", args: ["%\(chat_id)%"], num_items: 1)
		let return_val: Data

		if image_name.count == 0 || image_name[0].count == 0 {
			return_val = NSImage(named: "profile")?.tiffRepresentation ?? Data()
		} else {
			let image_name_string = (image_name[0]["ZUNIQUEID"] ?? "").split(separator: ":")[0]
			let image_path = URL(fileURLWithPath: Const.contact_images_address + image_name_string)

			do {
				return_val = try Data.init(contentsOf: image_path)
			} catch {
				return_val = NSImage(named: "profile")?.tiffRepresentation ?? Data()
			}
		}

		#endif

		closeDatabase(&contact_db)

		return return_val
	}

	final func returnImageDataDB(chat_id: String, contact_db: OpaquePointer, image_db: OpaquePointer, sms_db: OpaquePointer) -> Data {
		/// This returns the profile picture for someone with the phone number or email `chat_id` as pure image data

		Const.log("Getting image data with db for chat_id \(chat_id)")

		if chat_id == "default" {
			return SMImage(named: "profile").parseableData() ?? Data()
		}

		if chat_id.prefix(4) == "chat" && !chat_id.contains("@") && chat_id.count >= 20 {
			/// This is a kinda hacky workaround to get the image for a group
			/// So basically, whenever a group image is set, a message is inserted into the SMS database with a `group_action_type` of 1 and 1 attachment
			/// The attachment is the new profile picture for the group. So this just grabs the most recent message with 1 for the `group_action_type`,
			/// gets the location of its associated attachment, and returns that.
			let image_location = selectFromSql(
				db: sms_db,
				columns: ["filename"],
				table: "attachment",
				condition: "where ROWID in (select attachment_id from message_attachment_join where message_id in (select ROWID from message where group_action_type is 1 and cache_has_attachments is 1 and ROWID in (select message_id from chat_message_join where chat_id in (select ROWID from chat where chat_identifier is ?)) order by date DESC))",
				args: [chat_id],
				num_items: 1
			)

			guard image_location.count == 1, let image_url = image_location[0]["filename"] else {
				return returnImageDataDB(chat_id: "default", contact_db: contact_db, image_db: image_db, sms_db: sms_db)
			}

			let image = SMImage(image_url.replacingOccurrences(of: "~", with: "/var/mobile"))
			return image.parseableData() ?? Data()
		}

		var docid = [[String:String]]()

		var fixed_num = chat_id
		if chat_id.contains(",") {
			/// Just turns it into a proper sql condition based on if the specific address is an email or number
			let splits = chat_id.split(separator: ",").map({(String($0).contains("@") ? "c17Email" : "c16Phone") + " like ?"})
			fixed_num = splits.joined(separator: " or ")
		}

		/// get docid. docid is the identifier that corresponds to each contact, allowing for us to get their image
		if chat_id.contains(",") { /// Multiple addresses in one
			docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE \(fixed_num)", args: chat_id.split(separator: ",").map({"%\($0)%"}), num_items: 1)
		} else if chat_id.contains("@") { /// if an email
			docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c17Email LIKE ?", args: ["%\(chat_id)%"], num_items: 1)
		} else if chat_id.contains("+") {
			docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE ?", args: ["%\(chat_id)%"], num_items: 1)
		} else {
			docid = selectFromSql(db: contact_db, columns: ["docid"], table: "ABPersonFullTextSearch_content", condition: "WHERE c16Phone LIKE ? and c16Phone NOT LIKE \"%+%\"", args: ["%\(chat_id) "], num_items: 1)
		}

		guard docid.count > 0 else { return Data() }

		/// each contact image is stored as a blob in the sqlite database, not as a file.
		/// That's why we need a special query to get it, and can't use the selectFromSql function(s).
		let sqlString = "SELECT data FROM ABThumbnailImage WHERE record_id is \(docid[0]["docid"] ?? "") order by format asc limit 1;"

		var statement: OpaquePointer?

		Const.log("opened statement")

		if sqlite3_prepare_v2(image_db, sqlString, -1, &statement, nil) != SQLITE_OK {
			let errmsg = String(cString: sqlite3_errmsg(image_db)!)
			Const.log("WARNING: error preparing select: \(errmsg)", warning: true)

			return Data()
		}

		var jpgdata: Data = Data()

		if sqlite3_step(statement) == SQLITE_ROW {
			if let tiny_return_blob = sqlite3_column_blob(statement, 0) {

				/// Getting the data
				let len: Int32 = sqlite3_column_bytes(statement, 0)
				let dat: NSData = NSData(bytes: tiny_return_blob, length: Int(len))

				jpgdata = dat as Data
			}
		}

		if sqlite3_finalize(statement) != SQLITE_OK {
			let errmsg = String(cString: sqlite3_errmsg(image_db)!)
			Const.log("WARNING: error finalizing prepared statement: \(errmsg)", warning: true)
		}

		statement = nil
		Const.log("destroyed statement")

		return jpgdata
	}

	final func getAttachmentFromMessage(mid: String) -> [[String:String]] {
		/// This returns the file path for all attachments associated with a certain message with the message_id of `mid`

		Const.log("Getting attachment for mid \(mid)")

		/// create connection, get attachments information
		var db = createConnection()
		if db == nil { return [[String:String]]() }

		var files = selectFromSql(db: db, columns: ["filename", "mime_type"], table: "attachment", condition: "WHERE ROWID in (SELECT attachment_id from message_attachment_join WHERE message_id is ?)", args: [Int(mid) ?? 0])

		for i in 0..<files.count {
			files[i]["filename"] = String(files[i]["filename"]?.dropFirst(Const.attachment_address_prefix.count - Const.user_home_url.count + 2) ?? "")
		}

		closeDatabase(&db)

		return files
	}

	final func getAttachmentType(path: String) -> String {
		/// This gets the file type of the attachment at `path`

		Const.log("Getting attachment type for @ \(path)")

		var db = createConnection()
		if db == nil { return "" }

		let file_type_array = selectFromSql(db: db, columns: ["mime_type"], table: "attachment", condition: "WHERE filename like ?", args: ["%\(path)%"], num_items: 1)
		let return_val = file_type_array.count > 0 ? file_type_array[0]["mime_type"] ?? "image/jpeg" : "image/jpeg"

		closeDatabase(&db)

		return return_val
	}

	final func getAttachmentDataFromPath(path: String) -> [Any] { /// [0] = data, [1] = mime_type
		/// This returns the pure data of a file (attachment) at `path`

		Const.log("Getting attachment data from path \(path)")

		let parsed_path = path.replacingOccurrences(of: "/../", with: "/") /// To prevent LFI
		let type = getAttachmentType(path: parsed_path)
		var info: [Any] = [Data.init(capacity: 0), type]

		do {
			/// Pretty straightforward -- get data and return it
			if (type == "image/heic") { /// Since they're used so much
				let attachment_data = SMImage(Const.attachment_address_prefix + parsed_path).parseableData()

				if attachment_data == nil {
					Const.log("Failed to get JPEG data from HEIC Image at \(Const.attachment_address_prefix + parsed_path).", warning: true)
				}

				info[0] = attachment_data ?? Data() as Any
			} else {
				info[0] = try Data.init(contentsOf: URL(fileURLWithPath: Const.attachment_address_prefix + parsed_path))
			}
		} catch {
			Const.log("WARNING: failed to load image for path \(Const.attachment_address_prefix + parsed_path)", warning: true)
		}

		return info
	}

	final func searchForString(term: String, case_sensitive: Bool = false, bridge_gaps: Bool = true, group_by_time: Bool = true) -> Any {
		/// This gets all texts with `term` in them; `case_sensitive`, `bridge_gaps`, and `group_by_time` are customization options

		/// Create Connections
		var db = createConnection()
		var contact_db = createConnection(connection_string: Const.contacts_address)
		if db == nil || contact_db == nil { return [String:[[String:String]]]() }

		/// Replacing percentages with escaped so that they don't act as wildcard characters
		var upperTerm = term.replacingOccurrences(of: "%", with: "\\%")

		/// replace spaces with wildcard characters if bridge_gaps == true
		if bridge_gaps { upperTerm = upperTerm.split(separator: " ").joined(separator: "%") }

		var return_texts = [String:[[String:Any]]]()

		var texts: [[String:Any]] = selectFromSql(db: db, columns: ["c.chat_identifier", "c.display_name", "m.ROWID", "m.text", "m.service", "m.date", "m.cache_has_attachments"], table: "message m", condition: "inner join chat_message_join j on j.message_id = m.ROWID inner join chat c on j.chat_id = c.ROWID WHERE text like ? order by m.date desc", args: ["%\(upperTerm)%"], split_ids: true)

		/// If case sensitive, remove those who don't exactly match. sqlite select is hardcoded case insensitive
		if case_sensitive { texts.removeAll(where: { !(($0["text"] as! String).contains(term)) })}

		parseTexts(&texts, db: db, contact_db: contact_db)

		if !group_by_time {
			for i in texts {

				/// get sender for this text
				let chat = i["chat_identifier"] as! String

				/// Add this text onto the list of texts from this person that match term if grouping by person and not time
				if return_texts[chat] == nil {
					return_texts[chat] = [i]
				} else {
					return_texts[chat]?.append(i)
				}
			}
		} else {
			return_texts["texts"] = texts
		}

		return_texts["conversations"] = matchPartialAddressWithDB(term, db: contact_db)

		/// close
		closeDatabase(&db)
		closeDatabase(&contact_db)

		return return_texts
	}

	final func getPhotoList(num: Int = 40, offset: Int = 0, most_recent: Bool = true) -> [[String: Any]] {
		/// This gets a list of the `num` (most_recent ? most recent : oldest) photos, offset by `offset`.

		#if os(macOS)
		guard #available(OSX 10.15, *) else { return [[String:Any]]() }
		#endif

		Const.log("Getting list of photos, num: \(num), offset: \(offset), most recent: \(most_recent ? "true" : "false")")

		/// make sure that we have access to the photos library
		if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
			var con = true;

			PHPhotoLibrary.requestAuthorization({ auth in
				if auth != PHAuthorizationStatus.authorized {
					con = false
					Const.log("App is not authorized to view photos. Please grant access.", warning: true)
				}
			})
			guard con else { return [[String:Any]]() }
		}

		var ret_val = [[String:Any]].init(repeating: [String:Any](), count: num)
		let fetchOptions = PHFetchOptions()

		/// sort photos by most recent
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: !most_recent)]
		fetchOptions.fetchLimit = num + offset

		/// get images!
		let result = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
		let total = result.countOfAssets(with: PHAssetMediaType.image)
		let group = DispatchGroup()

		/// Here we iterate through the images and get their url
		for i in offset..<total {

			/// We have to use a dispatch group here to get all the image urls in order, since each uses an asynchronous callback to get them.
			group.enter()

			var local_result = [String:Any]()
			let image = result.object(at: i)

			/// Set up the options to grab the Image
			let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()

			options.canHandleAdjustmentData = { (adjustmeta: PHAdjustmentData) -> Bool in
				return true
			}

			/// Get the url here in this callback
			image.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in

				let url = contentEditingInput?.fullSizeImageURL as URL?

				/// Insert all the values into the return
				local_result["URL"] = url?.path.replacingOccurrences(of: Const.photo_address_prefix, with: "") ?? ""
				local_result["is_favorite"] = image.isFavorite

				/// Since we initialized `ret_val` to a set number of spaces, we can insert these at their correct index,
				/// instead of just appending them (and thus messing up the order)
				ret_val[i - offset] = local_result

				/// Leave the dispatch grop that we entered at the beginning of this iteration
				group.leave()
			})
		}

		/// Wait until there is nobody left in the group. This will occur once every image has been iterated through, and the url has been grabbed.
		group.wait()

		return ret_val
	}

	final func getPhotoDatafromPath(path: String) -> Data {
		/// This returns the pure data of a photo at `path`

		Const.log("Getting photo data from path \(path)")

		/// To prevent LFI
		let parsed_path = path.replacingOccurrences(of: "\\/", with: "/").replacingOccurrences(of: "../", with: "")
		let photo_data = SMImage(Const.photo_address_prefix + parsed_path).parseableData()

		return photo_data ?? Data()
	}

	final func getLinkInfo(_ mid: String, db: OpaquePointer?) -> [String:String] {
		/// This get a Rich Link's title text from the sql database. Was quite the pain to get working.
		/// I'll expland it in the future to get like the subtitle and other stuff too
		let sqlString = "SELECT payload_data from message where ROWID is \(mid);"

		var statement: OpaquePointer?
		var ret_dict = ["title": "Title", "subtitle": "Subtitle", "type": "Website"]

		Const.log("Opened statement in getLinkTitle")

		/// Prepare sql statement
		var ret_code = sqlite3_prepare_v2(db, sqlString, -1, &statement, nil)
		if ret_code != SQLITE_OK {
			Const.log("WARNING: error preparing select: \(ret_code)", warning: true)
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
			Const.log("WARNING: error finalizing statement: \(ret_code)", warning: true)
		}

		/// Blob data is technically an NSKeyedArchiver plist file. We just gotta serialize it and extract values
		var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
		var plistData = [String:AnyObject]()
		do {
			plistData = try PropertyListSerialization.propertyList(from: data as Data, options: .mutableContainersAndLeaves, format: &propertyListFormat) as? [String : AnyObject] ?? [String:AnyObject]()
		} catch {
			Const.log("WARNING: failed to decode plist for ROWID \(mid)", warning: true)
			statement = nil

			return ret_dict
		}

		statement = nil

		guard plistData.count > 0 else {
			return ret_dict
		}

		/// Always under object `$objects`
		let objects = plistData["$objects"] as! NSMutableArray

		guard objects.count > 5 else {
			return ret_dict
		}

		/// Since I haven't found a way to programatically find the correct values for these, I kinda have to hardcode
		/// some of the most-used values, such as rich links, podcast episodes, and gamepigeon messages.
		if objects.count > 30 && objects[21] as? String ?? "" == "GamePigeon" {
			ret_dict["title"] = objects[18] as? String ?? ""
		} else if objects.count >= 20 && (objects[19] as? [String:AnyObject] ?? [String:AnyObject]())["$classname"] as? String ?? "" == "LPiTunesMediaPodcastEpisodeMetadata" {
			ret_dict["title"] = objects[9] as? String ?? "Episode"
			ret_dict["subtitle"] = objects[10] as? String ?? "Podcast"
			ret_dict["type"] = "podcast"
		} else if objects.count >= 10, let title: String = objects[6] as? String {
			ret_dict["title"] = title
			let subtitle = objects[4] as? String ?? "//website/"
			ret_dict["subtitle"] = subtitle.split(separator: "/").count > 1 ? String(subtitle.split(separator: "/")[1]) : subtitle
			ret_dict["type"] = objects[9] as? String ?? "website"
		} else if objects.count >= 10 {
			ret_dict["title"] = objects[8] as? String ?? "No Title Available"
			ret_dict["subtitle"] = objects[9] as? String ?? "No subtitle available"
		}

		return ret_dict
	}

	final func getTextByGUID(_ guid: String) -> [String:Any] {
		Const.log("Getting text at guid \(guid)")

		var db = createConnection()
		var contact_db = createConnection(connection_string: Const.contacts_address)
		if db == nil || contact_db == nil { return [String:String]() }

		var text_array: [[String:Any]] = [[String:Any]]()

		for _ in 0..<10 {
			text_array = selectFromSql(
				db: db,
				columns: ["m.ROWID", "m.guid", "m.text", "m.subject", "m.is_from_me", "m.date", "m.service", "m.cache_has_attachments", "m.handle_id", "m.balloon_bundle_id", "m.associated_message_guid", "m.associated_message_type", "h.id", "c.chat_identifier", "c.room_name"],
				table: "message m",
				condition: "left join handle h on h.ROWID = m.handle_id inner join chat_message_join j on j.message_id = m.ROWID inner join chat c on j.chat_id = c.ROWID where m.guid is ?",
				args: [guid],
				num_items: 1,
				offset: 0,
				split_ids: true
			)

			if text_array.count > 0 { break }

			usleep(useconds_t(50000))  /// I hate race conditions so much but I have no idea how to avoid it for this
		}

		guard text_array.count > 0 else {
			return [String:String]()
		}

		parseTexts(&text_array, db: db, contact_db: contact_db, is_group: (text_array[0]["room_name"] as? String)?.count ?? 0 > 0)

		let text = text_array[0]

		Const.log("Closing databases and destroying pointers")
		closeDatabase(&db)
		closeDatabase(&contact_db)

		return text
	}

	final func getTapbackInformation(_ tapback: Int32, guid: String) -> [String:Any] {
		/// This gets the text information for a tapback with the value `tapback` and on the text with the guid `guid`

		Const.log("Getting tapback information with value \(tapback) and guid \(guid)")

		var db = createConnection()
		var contact_db = createConnection(connection_string: Const.contacts_address)
		if db == nil { return [String:String]() }

		var text_array: [[String:Any]] = [[String:Any]]()

		for _ in 0..<10 {
			text_array = selectFromSql(
				db: db,
				columns: ["m.ROWID", "m.guid", "m.text", "m.subject", "m.is_from_me", "m.date", "m.service", "m.cache_has_attachments", "m.handle_id", "m.balloon_bundle_id", "m.associated_message_guid", "m.associated_message_type", "h.id", "c.chat_identifier", "c.room_name"],
				table: "message m",
				condition: "left join handle h on h.ROWID = m.handle_id inner join chat_message_join j on j.message_id = m.ROWID inner join chat c on j.chat_id = c.ROWID where m.associated_message_guid like ? and m.associated_message_type is ?",
				args: ["%\(guid)%", Int(tapback)],
				num_items: 1,
				split_ids: true
			)

			if text_array.count > 0 { break }

			usleep(useconds_t(20000))  /// I hate race conditions so much but I have no idea how to avoid it for this
		}

		guard text_array.count > 0 else { return [String:String]() }

		parseTexts(&text_array, db: db, contact_db: contact_db, is_group: (text_array[0]["room_name"] as? String)?.count ?? 0 > 0)
		let text = text_array[0]

		Const.log("Closing connections and destroying pointers")
		closeDatabase(&contact_db)
		closeDatabase(&db)

		return text
	}

	final func matchPartialAddress(_ chat: String) -> [[String:String]] {
		Const.log("Matching partial address \(chat)")
		var ret = [[String:String]]()

		var db = createConnection(connection_string: Const.contacts_address)
		if db == nil { return ret }
		Const.log("Made connection with \(Const.contacts_address)")

		ret = matchPartialAddressWithDB(chat, db: db)

		Const.log("Closing database")
		closeDatabase(&db)

		return ret
	}

	final func matchPartialAddressWithDB(_ chat: String, db: OpaquePointer?) -> [[String:String]] {
		var ret = [[String:String]]()

		let matches = selectFromSql(
			db: db,
			columns: ["c0First", "c1Last", "c16Phone", "c17Email"],
			table: "ABPersonFullTextSearch_content",
			condition: "WHERE c17Email LIKE ? or c16Phone LIKE ?",
			args: ["%\(chat)%", "%\(chat)%"]
		)

		for m in matches {
			let add_str: String = m["c16Phone"] ?? "" + " " + (m["c17Email"] ?? "")
			let address: String = String(add_str.split(separator: " ").filter({ $0.contains(chat) }).max(by: {$1.count > $0.count}) ?? "")

			ret.append(["display_name": "\(m["c0First"] ?? "") \(m["c1Last"] ?? "")", "chat_id": address])
		}

		return ret
	}

	final func matchPartialName(_ name: String) -> [[String:Any]] {
		Const.log("Matching partial name \(name)")
		var ret = [[String:Any]]()

		var db = createConnection(connection_string: Const.contacts_address)
		if db == nil { return ret }
		Const.log("Made connection with \(Const.contacts_address)")

		ret = matchPartialNameWithDB(name, db: db)

		Const.log("Closing database")
		closeDatabase(&db)

		return ret
	}

	final func matchPartialNameWithDB(_ name: String, db: OpaquePointer?) -> [[String:Any]] {
		let splits = name.split(separator: " ")
		let first =  splits.first ?? ""
		let last = splits.last ?? first
		var ret: [[String:Any]] = [[String:Any]]()

		let matches = selectFromSql(
			db: db,
			columns: ["c0First", "c1Last", "c16Phone", "c17Email"],
			table: "ABPersonFullTextSearch_content",
			condition: "WHERE c0First LIKE ? or c1Last LIKE ?",
			args: ["%\(first)%", "%\(last)%"]
		)

		for m in matches {
			var addresses = Set(m["c17Email"]?.split(separator: " ").map({String($0)}) ?? [String]())
			let phones = m["c16Phone"]?.split(separator: " ").map({String($0)}) ?? [String]()

			var pluses = Set(phones.filter({$0.contains("+")}))
			for p in pluses {
				if pluses.filter({$0.contains(p) && $0 != p}).count > 0 {
					pluses.remove(p)
				} else {
					addresses.insert(p)
				}
			}

			let fullnums = phones.map({$0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()})
			outerfor: for p in fullnums {
				if phones.filter({$0.contains(p) && $0 != p}).count > 0 {
					continue
				}

				innerfor: for plus in pluses {
					if p.contains(plus.replacingOccurrences(of: "+", with: "")) {
						continue outerfor
					}
				}

				addresses.insert(p)
			}

			if addresses.count > 0 {
				ret.append(["name": "\(m["c0First"] ?? "") \(m["c1Last"] ?? "")", "addresses": Array(addresses)])
			}
		}

		return ret
	}

	final func getChatOfText(_ guid: String) -> String {
		Const.log("Getting chat of text \(guid)")
		var ret = ""

		var db = createConnection()
		if db == nil { return "" }

		let chat_query = selectFromSql(
			db: db,
			columns: ["chat_identifier"],
			table: "chat",
			condition: "where ROWID in (select chat_id from chat_message_join where message_id in (select ROWID from message where guid is ?))",
			args: [guid],
			num_items: 1
		)

		if chat_query.count > 0, let id = chat_query[0]["chat_identifier"] {
			ret = id
		}

		Const.log("Closing database")
		closeDatabase(&db)

		return ret
	}
}

import os

struct Const {
	static let api_msg_req: String = "messages"
	static let api_msg_num: String = "num_messages"
	static let api_msg_off: String = "messages_offset"
	static let api_msg_read: String = "read_messages"
	static let api_msg_from: String = "messages_from"

	static let api_msg_vals = [
		api_msg_req,
		api_msg_num,
		api_msg_off,
		api_msg_read,
		api_msg_from,
	]

	static let api_chat_req: String = "chats"
	static let api_chat_off: String = "chats_offset"

	static let api_chat_vals = [
		api_chat_req,
		api_chat_off
	]

	static let api_name_req: String = "name"

	static let api_search_req: String = "search"
	static let api_search_case: String = "search_case"
	static let api_search_bridge: String = "search_gaps"
	static let api_search_group: String = "search_group"

	static let api_search_vals = [
		api_search_req,
		api_search_case,
		api_search_bridge,
		api_search_group
	]

	static let api_photo_req: String = "photos"
	static let api_photo_off: String = "photos_offset"
	static let api_photo_recent: String = "photos_recent"

	static let api_photo_vals = [
		api_photo_req,
		api_photo_off,
		api_photo_recent
	]

	static let api_tap_req: String = "tapback"
	static let api_tap_guid: String = "tap_guid"
	static let api_tap_chat: String = "tap_in_chat"
	static let api_tap_rem: String = "remove_tap"

	static let api_tap_vals = [
		api_tap_req,
		api_tap_guid,
		api_tap_chat,
		api_tap_rem
	]

	static let api_del_chat: String = "delete_chat"
	static let api_del_text: String = "delete_text"

	static let api_del_vals = [
		api_del_chat,
		api_del_text
	]

	static let custom_css_path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("smserver_custom.css")
	static let contacts_address: String = "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb"
	static let contact_images_address: String = "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb"
	static let sms_db_address: String = "/private/var/mobile/Library/SMS/sms.db"
	static let attachment_address_prefix: String = "/private/var/mobile/Library/SMS/"
	static let photo_address_prefix: String = "/var/mobile/Media/"
	static let user_home_url: String = "/private/var/mobile/"

	static let log_prefix: String = "SMServer_app: "
	static let log_warning: String = "WARNING: "

	static func log(_ s: String, debug: Bool, warning: Bool = false) {
		/// This logs to syslog
		if debug || warning {
			os_log("%{public}@%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, Const.log_prefix, warning ? Const.log_warning : "", s)
		}
	}

	static func getWiFiAddress() -> String? {
		/// Gets the private IP of the host device

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
			if addrFamily == UInt8(AF_INET) {

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
}

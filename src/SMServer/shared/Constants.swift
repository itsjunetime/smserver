import Foundation
import os

#if os(macOS)
import IOKit.ps
#elseif os(iOS)
import SwiftUI
#endif

@objc
class Const : NSObject {
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
	static let api_tap_rem: String = "remove_tap"

	static let api_tap_vals = [
		api_tap_req,
		api_tap_guid,
		api_tap_rem
	]

	static let api_del_chat: String = "delete_chat"
	static let api_del_text: String = "delete_text"

	static let api_del_vals = [
		api_del_chat,
		api_del_text
	]

	static let api_config: String = "config"
	static let api_match_keyword: String = "match"
	static let api_match_type: String = "match_type"

	static let api_match_vals = [
		api_match_keyword,
		api_match_type
	]

	static let custom_css_path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("smserver_custom.css")

	#if os(iOS)

	static let contacts_address: String = "/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb"
	static let contact_images_address: String = "/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb"
	static let sms_db_address: String = "/private/var/mobile/Library/SMS/sms.db"
	static let attachment_address_prefix: String = "/private/var/mobile/Library/SMS/"
	static let photo_address_prefix: String = "/var/mobile/Media/"
	static let user_home_url: String = "/private/var/mobile/"
	static let cert_pass_file: String = Bundle.main.bundlePath + "/smserver_cert_pass.txt"

	static let help_string = """
	usage: \(col)1m./smserver [options]\(col)0m

	\(col)1mOptions:\(col)0m

	\(cmd_server_port_short), \(cmd_server_port):
		This sets the port that the HTTP server will run on, and requires a value to be passed in immediately after this flag.
		For example, to set the server port to 4000, you'd run \(col)1msmserver \(cmd_server_port) 4000\(col)0m. The default server port is 8741.

	\(cmd_socket_port_short), \(cmd_socket_port):
		This sets the port that the websocket will run on, and requires a value to be passed in immediately after this flag. The default socket port is 8740.

	\(cmd_socket_subdir):
		Only use this option if you are running SMServer behind a proxy of some kind -- this allows SMServer to tell the web interface what subdirectory the websocket
		is communicating from. If you do not call this flag, it is assumed that you are not running SMServer behind a proxy

	\(cmd_password):
		This sets the password for the server, and requires a value to be passed in immediately after this flag. The default password for the server is 'toor'.

	\(cmd_theme_short), \(cmd_theme):
		This sets the theme for the web interface, which must be one of the following: \(cmd_theme_options.joined(separator: ",")),
		and requires a value to be passed in immediately after this flag.

	\(cmd_def_chats), \(cmd_def_messages), \(cmd_def_photos):
		This sets the number of chats, messages, or photos to be loaded, respectively (if URL queries don't specify otherwise),
		and requires a value to be passed in immediately after this flag. The default number of chats is 40, messages is 100, and photos is 40.

	\(cmd_auth_short), \(cmd_auth), \(cmd_no_auth):
		This will enable or disable authentication, respective to which flag you pass in. The default is enabled.

	\(cmd_web_short), \(cmd_web), \(cmd_no_web):
		This will enable or disable the web interface, respective to which flag you pass in. The default is enabled.

	\(cmd_secure_short), \(cmd_secure), \(cmd_no_secure):
		This will enable or disable TLS for the connection with the server, respective to which flag you pass in. The default is enabled.

	\(cmd_subject_short), \(cmd_subject), \(cmd_no_subject):
		This will enable or disable the subject line in the web interface, respective to which flag you pass in. The default is disabled.

	\(cmd_typing_short), \(cmd_typing), \(cmd_no_typing):
		This will enable or disable sending of typing indicators from the server to other conversations,
		respective to which flag you pass in. The default is enabled.

	\(cmd_contacts_short), \(cmd_contacts), \(cmd_no_contacts):
		If this option is enabled, conversations will be combined with the other conversations that are assigned to the same contact
		on the host device. If this option is disabled, they will not. The default is disabled.

	\(cmd_background_short), \(cmd_background), \(cmd_no_background):
		This will allow the app to run in the background, even after you've exited this terminal session; it must be run in conjunction
		with the shell backgrounder (\(col)1m&\(col)0m). Without this flag, the server will die as soon as you exit the terminal session. The default is disabled.

	\(cmd_debug_short), \(cmd_debug), \(cmd_no_debug):
		This will enable or disable printing debug messages to the console. The default is disabled.

	\(cmd_web_short), \(cmd_web), \(cmd_no_web):
		This will enable or disable the web interface (not the API). The default is enabled.
	"""

	#elseif os(macOS)

	#if DEBUG
	static let user_home_url: String = "/Users/ian/"
	#else
	static let user_home_url: String = FileManager.default.homeDirectoryForCurrentUser.path
	#endif

	static let sources_dir = user_home_url + "Library/Application Support/AddressBook/Sources/"
	static let address_book_path: String = sources_dir + (FileManager.default.subpaths(atPath: sources_dir)?[0] ?? "*") + "/"

	static let contacts_address: String = address_book_path + "AddressBook-v22.abcddb"
	static let contact_images_address: String = address_book_path + "Images/"
	static let sms_db_address: String = user_home_url + "Library/Messages/chat.db"
	static let attachment_address_prefix: String = user_home_url + "Library/Messages/"
	static let photo_address_prefix: String = ""

	static let config_file_url: URL = URL(fileURLWithPath: user_home_url + "/.config/smserver/server.yaml") /// subject to change
	static let html_dir: URL = URL(fileURLWithPath: user_home_url + "/.smserver/")
	static let cert_pass_file: String = html_dir.path + "/smserver_cert_pass.txt"

	static let help_string = """
	usage: \(col)1m./smserver [options]\(col)0m

	\(col)1mOptions:\(col)0m

	\(cmd_server_port_short), \(cmd_server_port):
		This sets the port that the HTTP server will run on, and requires a value to be passed in immediately after this flag. For example, to set the server port to 4000, you'd run \(col)1msmserver \(cmd_server_port) 4000\(col)0m. The default server port is 8741.

	\(cmd_socket_port_short), \(cmd_socket_port):
		This sets the port that the websocket will run on, and requires a value to be passed in immediately after this flag. The default socket port is 8740.

	\(cmd_config_file_short), \(cmd_config_file):
		\(col)1mCURRENTLY INEFFECTIVE\(col)0m This sets the configuration file for SMServer to read from, and requires a value to be passed in immediately after this flag. The default configuration file location is \(config_file_url.path.replacingOccurrences(of: "file://", with: "")).

	\(cmd_html_dir_short), \(cmd_html_dir):
		\(col)1mCURRENTLY INEFFECTIVE\(col)0m This sets the directory at which SMServer should look for the web interface files (e.g. chats.html, style.css, etc), and requires a value to be passed in immediately after this flag. The default directory is \(html_dir.path.replacingOccurrences(of: "file://", with: "")).

	\(cmd_password):
		This sets the password for the server, and requires a value to be passed in immediately after this flag. The default password for the server is 'toor'.

	\(cmd_theme_short), \(cmd_theme):
		This sets the theme for the web interface, which must be one of the following: \(cmd_theme_options.joined(separator: ",")), and requires a value to be passed in immediately after this flag.

	\(cmd_def_chats), \(cmd_def_messages), \(cmd_def_photos):
		This sets the number of chats, messages, or photos to be loaded, respectively (if URL queries don't specify otherwise), and requires a value to be passed in immediately after this flag. The default number of chats is 40, messages is 100, and photos is 40.

	\(cmd_auth_short), \(cmd_auth), \(cmd_no_auth):
		This will enable or disable authentication, respective to which flag you pass in. The default is enabled.

	\(cmd_web_short), \(cmd_web), \(cmd_no_web):
		This will enable or disable the web interface, respective to which flag you pass in. The default is enabled.

	\(cmd_secure_short), \(cmd_secure), \(cmd_no_secure):
		This will enable or disable TLS for the connection with the server, respective to which flag you pass in. The default is enabled.

	\(cmd_subject_short), \(cmd_subject), \(cmd_no_subject):
		This will enable or disable the subject line in the web interface, respective to which flag you pass in. The default is disabled.

	\(cmd_typing_short), \(cmd_typing), \(cmd_no_typing):
		This will enable or disable sending of typing indicators from the server to other conversations, respective to which flag you pass in. The default is enabled.

	\(cmd_contacts_short), \(cmd_contacts), \(cmd_no_contacts):
		\(col)1mCURRENTLY INEFFECTIVE\(col)0m If this option is enabled, conversations will be combined with the other conversations that are assigned to the same contact on the host device. If this option is disabled, they will not. The default is disabled.
	"""

	#endif

	static let cmd_server_port: String = "--server_port"
	static let cmd_server_port_short: String = "-p"
	static let cmd_socket_port: String = "--socket_port"
	static let cmd_socket_port_short: String = "-w"
	static let cmd_socket_subdir: String = "--subdir"
	static let cmd_config_file: String = "--config"
	static let cmd_config_file_short: String = "-c"

	static let cmd_html_dir: String = "--html_dir"
	static let cmd_html_dir_short: String = "-m"
	static let cmd_password: String = "--password"
	static let cmd_theme: String = "--theme"
	static let cmd_theme_short: String = "-t"

	static let cmd_theme_options: [String] = [
		"light", "dark", "nord"
	]

	static let cmd_def_chats: String = "--default_chats"
	static let cmd_def_messages: String = "--default_messages"
	static let cmd_def_photos: String = "--default_photos"

	static let cmd_auth: String = "--authentication"
	static let cmd_auth_short: String = "-a"
	static let cmd_no_auth: String = "--no_authentication"
	static let cmd_web: String = "--web_interface"
	static let cmd_web_short: String = "-i"
	static let cmd_no_web: String = "--no_web_interface"
	static let cmd_secure: String = "--secure"
	static let cmd_secure_short: String = "-s"
	static let cmd_no_secure: String = "--no_secure"
	static let cmd_debug: String = "--debug"
	static let cmd_debug_short: String = "-d"
	static let cmd_no_debug: String = "--no_debug"

	static let cmd_subject: String = "--subject"
	static let cmd_subject_short: String = "-j"
	static let cmd_no_subject: String = "--no_subject"
	static let cmd_typing: String = "--typing"
	static let cmd_typing_short: String = "-y"
	static let cmd_no_typing: String = "--no_typing"
	static let cmd_contacts: String = "--contacts"
	static let cmd_contacts_short: String = "-o"
	static let cmd_no_contacts: String = "--no_contacts"

	static let cmd_show_help: String = "--help"
	static let cmd_show_help_short: String = "-h"
	static let cmd_background: String = "--background"
	static let cmd_background_short: String = "-b"
	static let cmd_no_background: String = "--no_background"

	static let cmd_req_vals = [
		cmd_server_port, cmd_server_port_short,
		cmd_socket_port, cmd_socket_port_short,
		cmd_config_file, cmd_config_file_short,
		cmd_html_dir, cmd_html_dir_short,
		cmd_password, cmd_socket_subdir,
		cmd_theme, cmd_theme_short,
		cmd_def_chats, cmd_def_messages, cmd_def_photos
	]

	static let cmd_bool_vals = [
		cmd_auth, cmd_auth_short, cmd_no_auth,
		cmd_web, cmd_web_short, cmd_no_web,
		cmd_secure, cmd_secure_short, cmd_no_secure,
		cmd_subject, cmd_subject_short, cmd_no_subject,
		cmd_typing, cmd_typing_short, cmd_no_subject,
		cmd_contacts, cmd_contacts_short, cmd_no_contacts,
		cmd_debug, cmd_debug_short, cmd_no_debug,
		cmd_show_help, cmd_show_help_short,
		cmd_background, cmd_background_short, cmd_no_background
	]

	static let col = "\u{001B}["


	static let log_prefix: String = "SMServer_app: "
	static let log_warning: String = "WARNING: "

	static func log(_ s: String, warning: Bool = false) {
		/// This logs to syslog
		if Settings.shared().debug || warning {
			if CommandLine.argc > 1 {
				print("\(log_prefix)\(warning ? log_warning : "")\(s)")
			} else {
				os_log("%{public}@%{public}@%{public}@", log: OSLog(subsystem: "com.ianwelker.smserver", category: "debugging"), type: .debug, log_prefix, warning ? log_warning : "", s)
			}
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

	static func getOSVersion() -> Double {
		#if os(macOS)
			return Double("\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)") ?? 10.12
		#elseif os(iOS)
			return Double(UIDevice.current.systemVersion) ?? 13.0
		#endif
	}

	static func getBatteryLevel() -> Double {
		#if os(macOS)
			let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
			let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
			let info = IOPSGetPowerSourceDescription(snapshot, sources.first).takeUnretainedValue() as! [String: AnyObject]

			return Double(info[kIOPSCurrentCapacityKey] as? Int ?? 0) / Double(info[kIOPSMaxCapacityKey] as? Int ?? 100)
		#elseif os(iOS)
			return Double(UIDevice.current.batteryLevel) * 100
		#endif
	}

	static func getBatteryState() -> BatteryState {
		#if os(macOS)
			let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
			let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
			let info = IOPSGetPowerSourceDescription(snapshot, sources.first).takeUnretainedValue() as! [String: AnyObject]

			if Double(info[kIOPSCurrentCapacityKey] as? Int ?? 0) / Double(info[kIOPSMaxCapacityKey] as? Int ?? 100) > 97 {
				return .full
			} else {
				let charging: Bool? = info[kIOPSIsChargingKey] as? Bool

				if charging == nil {
					return .unknown
				} else if charging! == true {
					return .charging
				} else {
					return .unplugged
				}
			}

		#elseif os(iOS)
			if UIDevice.current.batteryState == .charging {
				return .charging
			} else if UIDevice.current.batteryState == .unplugged {
				return .unplugged
			} else if UIDevice.current.batteryState == .full {
				return .full
			} else {
				return .unknown
			}
		#endif
	}

	static func getRelativeTime(ts: Double) -> String {
		let unix_ts: Double = (ts / 1000000000.0) + 978307200.0
		let date = Date(timeIntervalSince1970: unix_ts)
		let now = Date.init(timeIntervalSinceNow: 0)
		let calendar = Calendar.current

		let days_from = calendar.dateComponents([.day], from: date, to: now).day!

		if days_from == 0 {
			let date_dow = calendar.component(.weekday, from: date)
			let now_dow = calendar.component(.weekday, from: now)

			if date_dow != now_dow {
				return "Yesterday"
			}

			let date_hours = calendar.component(.hour, from: date)
			let date_min = calendar.component(.minute, from: date)

			return "\(date_hours):\(date_min < 10 ? "0" : "")\(date_min)"
		} else if days_from <= 8 {
			let date_dow = calendar.component(.weekday, from: date)
			let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
			return days[date_dow - 1]
		} else {
			let formatter = DateFormatter()

			if Locale.current.identifier == "en_US" {
				formatter.setLocalizedDateFormatFromTemplate("MM/dd/yy")
			} else {
				formatter.setLocalizedDateFormatFromTemplate("dd/MM/yy")
			}

			return formatter.string(from: date)
		}
	}
}

enum BatteryState {
	case charging
	case unplugged
	case full
	case unknown
}

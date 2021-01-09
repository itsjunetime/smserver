import Foundation

class Settings {
	var server_port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
	var socket_port: Int = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740
	var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
	var socket_subdirectory: String? = UserDefaults.standard.object(forKey: "socket_subdirectory") as? String? ?? nil

	var default_num_chats: Int = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 40
	var default_num_messages: Int = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 100
	var default_num_photos: Int = UserDefaults.standard.object(forKey: "num_photos") as? Int ?? 40

	var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	var require_authentication: Bool = UserDefaults.standard.object(forKey: "require_auth") as? Bool ?? true
	var background: Bool = UserDefaults.standard.object(forKey: "enable_backgrounding") as? Bool ?? true
	var light_theme: Bool = UserDefaults.standard.object(forKey: "light_theme") as? Bool ?? false
	var nord_theme: Bool = UserDefaults.standard.object(forKey: "nord_theme") as? Bool ?? false
	var is_secure: Bool = UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true
	var authenticated_addresses: [String] = UserDefaults.standard.object(forKey: "authenticated_addresses") as? [String] ?? [String]()

	var mark_when_read: Bool = UserDefaults.standard.object(forKey: "mark_when_read") as? Bool ?? true
	var override_no_wifi: Bool = UserDefaults.standard.object(forKey: "override_no_wifi") as? Bool ?? false
	var subjects_enabled: Bool = UserDefaults.standard.object(forKey: "subjects_enabled") as? Bool ?? false
	var send_typing: Bool = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true
	var combine_contacts: Bool = UserDefaults.standard.object(forKey: "combine_contacts") as? Bool ?? false
	var start_on_load: Bool = UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false
	var reload_on_network_change: Bool = UserDefaults.standard.object(forKey: "reload_on_network_change") as? Bool ?? true

	#if os(macOS)
	var config_file_url: String = Const.config_file_url.path
	var html_dir: String = Const.html_dir.path
	var run_web_interface: Bool = true /// no UserDefaults since rn only iOS needs that
	var show_help: Bool = false
	#endif

	private static var sharedSettings: Settings = {
		let settings = Settings()
		return settings
	}()

	class func shared() -> Settings {
		return sharedSettings
	}
}

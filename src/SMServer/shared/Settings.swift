import Foundation

class Settings {
	var server_port: Int = UserDefaults.standard.object(forKey: "port") as? Int ?? 8741
	var socket_port: Int = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740
	var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"
	var socket_subdirectory: String? = UserDefaults.standard.object(forKey: "socket_subdirectory") as? String
	/// This passphrase is found in a hidden file that doesn't exist in the git repo. This is so that nobody can extract the private key from the pfx file
	var cert_pass: String = PKCS12Identity.pass

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
	var displayed_messages: [String] = [String]()
	var read_messages: [String] = [String]()

	var mark_when_read: Bool = UserDefaults.standard.object(forKey: "mark_when_read") as? Bool ?? true
	var override_no_wifi: Bool = UserDefaults.standard.object(forKey: "override_no_wifi") as? Bool ?? false
	var subjects_enabled: Bool = UserDefaults.standard.object(forKey: "subjects_enabled") as? Bool ?? false
	var send_typing: Bool = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true
	var combine_contacts: Bool = UserDefaults.standard.object(forKey: "combine_contacts") as? Bool ?? false
	var start_on_load: Bool = UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false
	var reload_on_network_change: Bool = UserDefaults.standard.object(forKey: "reload_on_network_change") as? Bool ?? true
	var run_web_interface: Bool = UserDefaults.standard.object(forKey: "run_web_interface") as? Bool ?? true

	var show_help: Bool = false
	var cli_background: Bool = false

	#if os(macOS)
	var config_file_url: String = Const.config_file_url.path
	var html_dir: String = Const.html_dir.path
	#endif

	private static var sharedSettings: Settings = {
		let settings = Settings()
		return settings
	}()

	class func shared() -> Settings {
		return sharedSettings
	}

	func parseArgs() {
		let settings = Settings.shared()
		var past_val = false

		#if DEBUG // ugh. Apple. just don't pass in unnecessary cmdline args and everything will be fine.
		let args = Array(CommandLine.arguments.dropFirst()).filter({ $0 != "-NSDocumentRevisionsDebugMode" })
		#else
		let args = Array(CommandLine.arguments.dropFirst())
		#endif

		for i in 0..<args.count {
			if past_val {
				past_val = false
				continue
			}

			let opt = args[i]

			if (opt.prefix(2) == "--" && !Const.cmd_req_vals.contains(opt) && !Const.cmd_bool_vals.contains(opt)) || opt.prefix(1) != "-" {
				print("Option \(opt) not recognized. Ignoring...")
				continue
			}

			if Const.cmd_req_vals.contains(opt) {
				past_val = true
				if i == args.count - 1 {
					print("Please enter a value for the option \(opt)")
					continue
				}

				let val = args[i+1]
				switch opt {
					case Const.cmd_server_port, Const.cmd_server_port_short:
						if let num = Int(val) {
							settings.server_port = num
						} else {
							print("Could not convert value \(val) to int. Server port will remain unaffected.")
						}
					case Const.cmd_socket_port, Const.cmd_socket_port_short:
						if let num = Int(val) {
							settings.socket_port = num
						} else {
							print("Could not convert value \(val) to int. Socket port will remain unaffected.")
						}
					case Const.cmd_socket_subdir:
						settings.socket_subdirectory = val
					case Const.cmd_password:
						settings.password = val
#if os(macOS)
					case Const.cmd_config_file, Const.cmd_config_file_short:
						if !FileManager.default.fileExists(atPath: val) {
							print("Cannot find file at \(val). Please ensure that you are passing in the absolute path and that a file exists at this location")
						} else {
							settings.config_file_url = val
						}
					case Const.cmd_html_dir, Const.cmd_html_dir_short:
						var is_dir: ObjCBool = true /// why? terrible design, apple. just make it a regular bool
						if !FileManager.default.fileExists(atPath: val, isDirectory: &is_dir) {
							print("Cannot find directory at \(val). Please ensure that you are passing in the absolute path and that a file exists at this location")
						} else {
							settings.html_dir = val
						}
#endif
					case Const.cmd_theme, Const.cmd_theme_short:
						if !Const.cmd_theme_options.contains(val) {
							print("\(val) is not a valid theme. Please enter only one of the following: \(Const.cmd_theme_options.joined(separator: ","))")
						} else {
							settings.nord_theme = val == "nord"
							settings.light_theme = val == "light"
						}
					case Const.cmd_def_chats, Const.cmd_def_messages, Const.cmd_def_photos:
						let num = Int(val)
						if let num = num {
							if opt == Const.cmd_def_chats {
								settings.default_num_chats = num
							} else if opt == Const.cmd_def_messages {
								settings.default_num_messages = num
							} else {
								settings.default_num_photos = num
							}
						} else {
							print("Could not convert value \(val) to int. Socket port will remain unaffected.")
						}
					default:
						print("Wow. You managed to input an option that both is and isn't in the options that require a value. Very impressive.")
				}
			} else {

				/// check if it's a lot of single letter options, like `-aisb`
				if opt.count > 2 && Array(opt)[1] != "-" {
					let forbidden: [String] = Const.cmd_req_vals.filter({ $0.count == 2 }).map({ String($0.suffix(1)) })

					for char in String(opt.suffix(opt.count - 1)) {
						let c = String(char)

						if forbidden.contains(c) {
							print("Please use option -\(c) by itself, as it requires a value. It will be ignored in this context.")
							continue
						}

						switch c {
							case Const.cmd_auth_short.suffix(1):
								settings.require_authentication = true
							case Const.cmd_web_short.suffix(1):
								settings.run_web_interface = true
							case Const.cmd_secure_short.suffix(1):
								settings.is_secure = true
							case Const.cmd_debug_short.suffix(1):
								settings.debug = true
							case Const.cmd_subject_short.suffix(1):
								settings.subjects_enabled = true
							case Const.cmd_typing_short.suffix(1):
								settings.send_typing = true
							case Const.cmd_contacts_short.suffix(1):
								settings.combine_contacts = true
							case Const.cmd_background_short.suffix(1):
								settings.cli_background = true
							case Const.cmd_show_help_short.suffix(1):
								settings.show_help = true
							default:
								print("Option -\(c) not recognized. Ignoring...")
						}
					}
				} else {
					switch opt {
						case Const.cmd_auth, Const.cmd_auth_short, Const.cmd_no_auth:
							settings.require_authentication = opt != Const.cmd_no_auth
						case Const.cmd_web, Const.cmd_web_short, Const.cmd_no_web:
							settings.run_web_interface = opt != Const.cmd_no_web
						case Const.cmd_secure, Const.cmd_secure_short, Const.cmd_no_secure:
							settings.is_secure = opt != Const.cmd_no_secure
						case Const.cmd_debug, Const.cmd_debug_short, Const.cmd_no_debug:
							settings.debug = opt != Const.cmd_no_debug
						case Const.cmd_subject, Const.cmd_subject_short, Const.cmd_no_subject:
							settings.subjects_enabled = opt != Const.cmd_no_subject
						case Const.cmd_typing, Const.cmd_typing_short, Const.cmd_no_typing:
							settings.send_typing = opt != Const.cmd_no_typing
						case Const.cmd_contacts, Const.cmd_contacts_short, Const.cmd_no_contacts:
							settings.combine_contacts = opt != Const.cmd_no_contacts
						case Const.cmd_background, Const.cmd_background_short, Const.cmd_no_background:
							settings.cli_background = opt != Const.cmd_no_background
						case Const.cmd_show_help, Const.cmd_show_help_short:
							settings.show_help = true
						default:
							print("Option -\(opt) not recognized. Ignoring...")
					}
				}
			}
		}
	}
}

import Foundation

func main() {
	let server = ServerDelegate()
	let settings = Settings.shared()
	parseArgs()

	guard !settings.show_help else {
		print(Const.help_string)
		exit(0)
	}

	print(server.startServers() ? "Started server & websocket..." : "Failed to start server and websocket...")
	
	while let string = readLine() {
		if string == "q" { break }
		else {
			print("got line: \(string)")
		}
	}
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
			let val = args[i+1]
			switch opt {
				case Const.cmd_server_port, Const.cmd_server_port_short:
					settings.server_port = val
				case Const.cmd_socket_port, Const.cmd_socket_port_short:
					let num = Int(val)
					if let num = num {
						settings.socket_port = num
					} else {
						print("Could not convert value \(val) to int. Socket port will remain unaffected.")
					}
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
				case Const.cmd_password:
					settings.password = val
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
						//case Const.cmd_contacts_short.suffix(1):
						//	settings.combine_contacts = true
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
					//case Const.cmd_contacts, Const.cmd_contacts_short, Const.cmd_no_contacts:
					//	settings.combine_contacts = opt != Const.cmd_no_contacts
					case Const.cmd_show_help, Const.cmd_show_help_short:
						settings.show_help = true
					default:
						print("Wow. You managed to input an option that both is and isn't in the options that require no value. Very impressive.")
				}
			}
		}
	}
}

main()

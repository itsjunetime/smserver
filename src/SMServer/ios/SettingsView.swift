import SwiftUI

struct SettingsView: View {
	let settings = Settings.shared()

	var grey_box = Color.init(red: 0.2, green: 0.2, blue: 0.2)

	private let picker_options: [String] = ["Dark", "Light", "Nord"]

	private let cl_red = 0.40
	private let cl_blu = 0.65

	@State private var show_alert: Bool = false
	@State private var alert_title: String = ""
	@State private var alert_text: String = ""

	/// Ideally we would make this equal to the object in settings that relates to this
	/// but in iOS, where this file is used, the items in settings always equal their `UserDefaults` counterparts.
	@State var socket_subdir_enabled: Bool = UserDefaults.standard.object(forKey: "socket_subdirectory") as? String? ?? nil != nil

	private func resetDefaults() {
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)

		self.alert_title = "Settings Reset"
		self.alert_text = "Your settings were reset to default"
	}

	var body: some View {

		let chats_binding = Binding<Int>(get: {
			self.settings.default_num_chats
		}, set: {
			self.settings.default_num_chats = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "num_chats")
		})

		let messages_binding = Binding<Int>(get: {
			self.settings.default_num_messages
		}, set: {
			self.settings.default_num_messages = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "num_messages")
		})

		let photos_binding = Binding<Int>(get: {
			self.settings.default_num_photos
		}, set: {
			self.settings.default_num_photos = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "num_photos")
		})

		let socket_binding = Binding<Int>(get: {
			self.settings.socket_port
		}, set: {
			if String($0) == self.settings.server_port {
				self.alert_title = "Error"
				self.alert_text = "The websocket port must be different from the main server port. Please change it to fix this."
				self.show_alert = true
			} else {
				self.settings.socket_port = Int($0)
				UserDefaults.standard.setValue(Int($0), forKey: "socket_port")
			}
		})

		let theme_binding = Binding<Int>(get: {
			self.settings.light_theme ? 1 : (self.settings.nord_theme ? 2 : 0)
		}, set: {
			self.settings.light_theme = $0 == 1
			self.settings.nord_theme = $0 == 2
			UserDefaults.standard.setValue(self.settings.light_theme, forKey: "light_theme")
			UserDefaults.standard.setValue(self.settings.nord_theme, forKey: "nord_theme")
		})

		let subject_binding = Binding<Bool>(get: {
			self.settings.subjects_enabled
		}, set: {
			self.settings.subjects_enabled = $0
			UserDefaults.standard.setValue($0, forKey: "subjects_enabled")
		})

		let typing_binding = Binding<Bool>(get: {
			self.settings.send_typing
		}, set: {
			self.settings.send_typing = $0
			UserDefaults.standard.setValue($0, forKey: "send_typing")
		})

		let read_binding = Binding<Bool>(get: {
			self.settings.mark_when_read
		}, set: {
			self.settings.mark_when_read = $0
			UserDefaults.standard.setValue($0, forKey: "mark_when_read")
		})

		let auth_binding = Binding<Bool>(get: {
			self.settings.require_authentication
		}, set: {
			self.settings.require_authentication = $0
			UserDefaults.standard.setValue($0, forKey: "require_auth")
		})

		let contacts_binding = Binding<Bool>(get: {
			self.settings.combine_contacts
		}, set: {
			self.settings.combine_contacts = $0
			UserDefaults.standard.setValue($0, forKey: "combine_contacts")
		})

		let socket_subdir_enabled_binding = Binding<Bool>(get: {
			self.socket_subdir_enabled
		}, set: {
			self.socket_subdir_enabled = $0
			self.settings.socket_subdirectory = $0 ? "" : nil
			UserDefaults.standard.setValue($0 ? "" : nil, forKey: "socket_subdirectory")
		})

		let socket_subdir_binding = Binding<String>(get: {
			self.settings.socket_subdirectory ?? ""
		}, set: {
			self.settings.socket_subdirectory = $0
			UserDefaults.standard.setValue($0, forKey: "socket_subdirectory")
		})

		let debug_binding = Binding<Bool>(get: {
			self.settings.debug
		}, set: {
			self.settings.debug = $0
			UserDefaults.standard.setValue($0, forKey: "debug")
		})

		let background_binding = Binding<Bool>(get: {
			self.settings.background
		}, set: {
			self.settings.background = $0
			UserDefaults.standard.setValue($0, forKey: "enable_backgrounding")
		})

		let secure_binding = Binding<Bool>(get: {
			self.settings.is_secure
		}, set: {
			self.settings.is_secure = $0
			UserDefaults.standard.setValue($0, forKey: "is_secure")
			self.alert_title = "Restart"
			self.alert_text = "Please restart the app for your new settings to take effect"
			self.show_alert = true
		})

		let override_binding = Binding<Bool>(get: {
			self.settings.override_no_wifi
		}, set: {
			self.settings.override_no_wifi = $0
			UserDefaults.standard.setValue($0, forKey: "override_no_wifi")
		})

		let load_binding = Binding<Bool>(get: {
			self.settings.start_on_load
		}, set: {
			self.settings.start_on_load = $0
			UserDefaults.standard.setValue($0, forKey: "start_on_load")
		})

		let reload_binding = Binding<Bool>(get: {
			self.settings.reload_on_network_change
		}, set: {
			self.settings.reload_on_network_change = $0
			UserDefaults.standard.setValue($0, forKey: "reload_on_network_change")
		})

		return ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				Text("Settings")
					.font(.largeTitle)

				Text("Load values")
					.font(.headline)

				Section {
					VStack {

						HStack {
							Text("Initial number of chats to load")
							Spacer()
							TextField("Chats", value: chats_binding, formatter: NumberFormatter())
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(width: 60)
						}

						HStack {
							Text("Initial number of messages to load")
							Spacer()
							TextField("Messages", value: messages_binding, formatter: NumberFormatter())
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(width: 60)
						}

						HStack {
							Text("Initial number of photos to load")
							Spacer()
							TextField("Photos", value: photos_binding, formatter: NumberFormatter())
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(width: 60)
						}

						HStack {
							Text("Websocket port")
							Spacer()
							TextField("Port", value: socket_binding, formatter: NumberFormatter())
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.frame(width: 60)
						}
					}
				}.padding(10)
				.background(grey_box)
				.cornerRadius(8)

				Spacer().frame(height: 14)

				HStack {
					Text("Theme")
						.font(.headline)

					Spacer().frame(width: 20)

					Picker(selection: theme_binding, label: Text("")) {
						ForEach(0..<self.picker_options.count, id: \.self) { i in
							return Text(self.picker_options[i]).tag(i)
						}
					}.pickerStyle(SegmentedPickerStyle())

				}

				Spacer().frame(height: 14)

				Section {

					Text("Web interface Settings")
						.font(.headline)

					Section {
						VStack(spacing: 8) {

							Toggle("Enable subject line", isOn: subject_binding)
							Toggle("Send typing indicators", isOn: typing_binding)
							Toggle("Automatically mark as read", isOn: read_binding)
							Toggle("Require Authentication", isOn: auth_binding)
							Toggle("Merge contact addresses (experimental)", isOn: contacts_binding)
							Toggle("WebSocket Proxy Compatibility", isOn: socket_subdir_enabled_binding)

							if socket_subdir_enabled {
								VStack(alignment: .leading) {
									Text("WebSocket subdirectory")
									TextField("e.g. /sms/socket", text: socket_subdir_binding)
										.textFieldStyle(RoundedBorderTextFieldStyle())
										.disableAutocorrection(true)
								}
							}

						}
					}.padding(10)
					.background(grey_box)
					.cornerRadius(8)
					.animation(.easeInOut(duration: 0.2))

					Spacer().frame(height: 8)

					Text("Miscellaneous")
						.font(.headline)

					Section {
						VStack(spacing: 8) {

							Toggle("Enable debug", isOn: debug_binding)
							Toggle("Enable backgrounding", isOn: background_binding)
							Toggle("Enable SSL", isOn: secure_binding)
							Toggle("Allow operation off of Wifi", isOn: override_binding)
							Toggle("Start server on app launch", isOn: load_binding)
							Toggle("Restart server on network change", isOn: reload_binding)

						}
					}.padding(10)
					.background(grey_box)
					.cornerRadius(8)

				}.alert(isPresented: $show_alert, content: {
					Alert(title: Text(self.alert_title), message: Text(self.alert_text))
				})

				/// ok so this VStack still has an absurd amount of padding on the top and bottom when you have a large text size, for some reason.
				/// I'll fix that eventually
				VStack(alignment: .leading) {
					ZStack {
						GeometryReader { proxy in
							/// makes vibrant, shiny text thing. Very nice. Padding is :( tho
							LinearGradient(
								gradient: Gradient(
									colors: [
										Color.init(red: self.cl_red, green: (Double(proxy.frame(in: .named("frameLayer")).minY) - 240) / 400, blue: self.cl_blu),
										Color.init(red: self.cl_red, green: (Double(proxy.frame(in: .named("frameLayer")).minY) - 310) / 400, blue: self.cl_blu)
									]
								),
								startPoint: .topLeading, endPoint: .bottomTrailing
							).mask(
								VStack {
									HStack {
										Text("View API Documentation")
											.aspectRatio(contentMode: .fill)
										Spacer()
										Image(systemName: "doc.text")
									}

									Spacer().frame(height: 20)

									HStack {
										Text("Donate to support SMServer")
										Spacer()
										Image(systemName: "link")
									}

									Spacer().frame(height: 20)

									HStack {
										Text("Reset Settings to Default")
										Spacer()
										Image(systemName: "arrow.clockwise")
									}
								}
							)
						}

						VStack {
							Button(action: {
								let github_url = URL(string: "https://github.com/iandwelker/smserver/blob/master/docs/API.md")
								guard let url = github_url, UIApplication.shared.canOpenURL(url) else { return }
								UIApplication.shared.open(url)
							}) {
								HStack {
									Text("hidden text :)").foregroundColor(Color.clear)
									Spacer()
								}
							}.padding(.bottom, 6)

							Button(action: {
								let paypal_url = URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=K3A6WVKT54PH4&item_name=Tweak%2FApplication+Development&currency_code=USD")
								guard let url = paypal_url, UIApplication.shared.canOpenURL(url) else { return }
								UIApplication.shared.open(url)
							}) {
								HStack {
									Text("hidden text :)").foregroundColor(Color.clear)
									Spacer()
								}
							}.padding(.init(top: 6, leading: 0, bottom: 6, trailing: 0))

							Button(action: {
								self.resetDefaults()
							}) {
								HStack {
									Text("hidden text :)").foregroundColor(Color.clear)
									Spacer()
								}
							}.padding(.top, 6)
						}
					}
				}.padding(10)
				.background(grey_box)
				.cornerRadius(8)

				Text("Compatible with libSMServer 0.6.1")
					.font(.callout)
					.foregroundColor(.gray)

			}.padding()
			.animation(.easeInOut(duration: 0.2))
		}.coordinateSpace(name: "frameLayer")
	}
}

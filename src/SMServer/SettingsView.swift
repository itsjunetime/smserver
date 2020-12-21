import SwiftUI

struct SettingsView: View {
	@State var default_num_chats = UserDefaults.standard.object(forKey: "num_chats") as? Int ?? 40
	@State var default_num_messages = UserDefaults.standard.object(forKey: "num_messages") as? Int ?? 100
	@State var default_num_photos = UserDefaults.standard.object(forKey: "num_photos") as? Int ?? 40
	@State var socket_port = UserDefaults.standard.object(forKey: "socket_port") as? Int ?? 8740

	@State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	@State var require_authentication: Bool = UserDefaults.standard.object(forKey: "require_auth") as? Bool ?? true
	@State var background: Bool = UserDefaults.standard.object(forKey: "enable_backgrounding") as? Bool ?? true
	@State var light_theme: Bool = UserDefaults.standard.object(forKey: "light_theme") as? Bool ?? false
	@State var nord_theme: Bool = UserDefaults.standard.object(forKey: "nord_theme") as? Bool ?? false
	@State var is_secure: Bool = UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true
	@State var mark_when_read: Bool = UserDefaults.standard.object(forKey: "mark_when_read") as? Bool ?? true
	@State var override_no_wifi: Bool = UserDefaults.standard.object(forKey: "override_no_wifi") as? Bool ?? false
	@State var subjects_enabled: Bool = UserDefaults.standard.object(forKey: "subjects_enabled") as? Bool ?? false
	@State var send_typing: Bool = UserDefaults.standard.object(forKey: "send_typing") as? Bool ?? true
	@State var combine_contacts: Bool = UserDefaults.standard.object(forKey: "combine_contacts") as? Bool ?? false

	var grey_box = Color("BeginningBlur")

	private let picker_options: [String] = ["Dark", "Light", "Nord"]

	@State private var display_ssl_alert: Bool = false
	@State private var display_port_alert: Bool = false

	private func resetDefaults() {
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
	}

	var body: some View {

		let chats_binding = Binding<Int>(get: {
			self.default_num_chats
		}, set: {
			self.default_num_chats = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "num_chats")
		})

		let messages_binding = Binding<Int>(get: {
			self.default_num_messages
		}, set: {
			self.default_num_messages = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "num_messages")
		})

		let photos_binding = Binding<Int>(get: {
			self.default_num_photos
		}, set: {
			self.default_num_photos = Int($0)
			UserDefaults.standard.setValue(Int($0), forKey: "num_photos")
		})

		let socket_binding = Binding<Int>(get: {
			self.socket_port
		}, set: {
			if String($0) == UserDefaults.standard.object(forKey: "port") as? String ?? "8741" {
				self.display_port_alert = true
			} else {
				self.socket_port = Int($0)
				UserDefaults.standard.setValue(Int($0), forKey: "socket_port")
			}
		})

		let theme_binding = Binding<Int>(get: {
			self.light_theme ? 1 : (self.nord_theme ? 2 : 0)
		}, set: {
			self.light_theme = $0 == 1
			self.nord_theme = $0 == 2
			UserDefaults.standard.setValue(self.light_theme, forKey: "light_theme")
			UserDefaults.standard.setValue(self.nord_theme, forKey: "nord_theme")
		})

		let subject_binding = Binding<Bool>(get: {
			self.subjects_enabled
		}, set: {
			self.subjects_enabled = $0
			UserDefaults.standard.setValue($0, forKey: "subjects_enabled")
		})

		let typing_binding = Binding<Bool>(get: {
			self.send_typing
		}, set: {
			self.send_typing = $0
			UserDefaults.standard.setValue($0, forKey: "send_typing")
		})

		let read_binding = Binding<Bool>(get: {
			self.mark_when_read
		}, set: {
			self.mark_when_read = $0
			UserDefaults.standard.setValue($0, forKey: "mark_when_read")
		})

		let auth_binding = Binding<Bool>(get: {
			self.require_authentication
		}, set: {
			self.require_authentication = $0
			UserDefaults.standard.setValue($0, forKey: "require_auth")
		})

		let contacts_binding = Binding<Bool>(get: {
			self.combine_contacts
		}, set: {
			self.combine_contacts = $0
			UserDefaults.standard.setValue($0, forKey: "combine_contacts")
		})

		let debug_binding = Binding<Bool>(get: {
			self.debug
		}, set: {
			self.debug = $0
			UserDefaults.standard.setValue($0, forKey: "debug")
		})

		let background_binding = Binding<Bool>(get: {
			self.background
		}, set: {
			self.background = $0
			UserDefaults.standard.setValue($0, forKey: "enable_backgrounding")
		})

		let secure_binding = Binding<Bool>(get: {
			self.is_secure
		}, set: {
			self.is_secure = $0
			UserDefaults.standard.setValue($0, forKey: "is_secure")
			self.display_ssl_alert = true
		})

		let override_binding = Binding<Bool>(get: {
			self.override_no_wifi
		}, set: {
			self.override_no_wifi = $0
			UserDefaults.standard.setValue($0, forKey: "override_no_wifi")
		})

		return ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				Text("Settings")
					.font(.largeTitle)

				Spacer().frame(height: 8)

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

						}
					}.padding(10)
					.background(grey_box)
					.cornerRadius(8)

					Spacer().frame(height: 8)

					Text("Miscellaneous")
						.font(.headline)

					Section {
						VStack(spacing: 8) {

							Toggle("Toggle debug", isOn: debug_binding)
							Toggle("Enable backgrounding", isOn: background_binding)
							Toggle("Enable SSL", isOn: secure_binding)
							Toggle("Allow operation off of Wifi", isOn: override_binding)

						}
					}.padding(10)
					.background(grey_box)
					.cornerRadius(8)

				}.alert(isPresented: $display_ssl_alert, content: {
					Alert(title: Text("Restart"), message: Text("Please restart the app for your new settings to take effect"))
				})
				.alert(isPresented: $display_port_alert, content: {
					Alert(title: Text("Error"), message: Text("The websocket port must be different from the main server port. Please change it to fix this."))
				})

				Section {

					Text("Compatible with libSMServer 0.5.4")
						.font(.callout)
						.foregroundColor(.gray)

					Spacer().frame(height: 15)

					HStack {
						Spacer()

						Button(action: {
							self.resetDefaults()
						}) {
							Text("Reset Defaults")
								.padding(.init(top: 8, leading: 24, bottom: 8, trailing: 24))
								.background(Color.blue)
								.cornerRadius(8)
								.foregroundColor(Color.white)
						}

						Spacer()
					}
				}

			}.padding()
		}
	}
}

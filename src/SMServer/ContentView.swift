import Foundation
import SwiftUI
import Photos

struct ContentView: View {
	let server = ServerDelegate()
	let geo_width: CGFloat = 0.6
	let font_size: CGFloat = 25

	@State var port: String = UserDefaults.standard.object(forKey: "port") as? String ?? "8741"
	@State var password: String = UserDefaults.standard.object(forKey: "password") as? String ?? "toor"

	@State var debug: Bool = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
	@State var secure: Bool = UserDefaults.standard.object(forKey: "is_secure") as? Bool ?? true
	@State var override_no_wifi: Bool = UserDefaults.standard.object(forKey: "override_no_wifi") as? Bool ?? false
	@State var background: Bool = UserDefaults.standard.object(forKey: "enable_backgrounding") as? Bool ?? true
	@State var start_on_load: Bool = UserDefaults.standard.object(forKey: "start_on_load") as? Bool ?? false

	@State var view_settings: Bool = false
	@State var server_running: Bool = false
	@State var show_picker: Bool = false
	@State var show_oseven_update: Bool = false

	func loadServer() {
		/// This starts the server at port $port_num
		Const.log("Attempting to load server and socket...", debug: self.debug)

		self.server_running = server.startServers()

		Const.log(self.server_running ? "Successfully started server and socket" : "Failed to start server and socket", debug: self.debug, warning: !self.server_running)
	}

	func enteredBackground() {
		/// Just waits a minute and then kills the app if you disabled backgrounding. A not graceful way of doing what the system does automatically
		//if !background || !self.server.isListening {
		if !background || !self.server.isRunning() {
			Const.log("sceneDidEnterBackground, starting kill timer", debug: self.debug)
			DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: {
				if UIApplication.shared.applicationState == .background {
					exit(0)
				}
			})
		}
	}

	func loadFuncs() {
		/// All the functions that run on scene load

		self.server.loadFuncs()

		if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
			PHPhotoLibrary.requestAuthorization({ auth in
				if auth != PHAuthorizationStatus.authorized {
					Const.log("App is not authorized to view photos. Please grant access.", debug: self.debug, warning: true)
				}
			})
		}

		if !(UserDefaults.standard.value(forKey: "shown_oseven_update_msg") as? Bool ?? false) {
			UserDefaults.standard.setValue(true, forKey: "shown_oseven_update_msg")
			self.show_oseven_update = true
		}

		if self.start_on_load && (Const.getWiFiAddress() != nil || self.override_no_wifi)  {
			loadServer()
		}
	}

	func reloadVars() {
		self.debug = UserDefaults.standard.object(forKey: "debug") as? Bool ?? false
		self.server.reloadVars()
	}

	func getHostname() -> String {
		let hnp: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>.allocate(capacity: 255)
		var _ = gethostname(hnp, 100)

		let new_str = String.init(cString: hnp!)

		free(hnp)
		return new_str /// this may not work at all. Let's see
	}

	var bottom_bar: some View { /// just to break up the code
		HStack {
			HStack {
				HStack {
					HStack {
						Button(action: {
							self.reloadVars()
						}) {
							Image(systemName: "goforward")
								.font(.system(size: self.font_size))
								.foregroundColor(Color.purple)
						}

						Spacer().frame(width: 24)

						Button(action: {
							if self.server_running { self.server.stopServers() }
						}) {
							Image(systemName: "stop.fill")
								.font(.system(size: self.font_size))
								.foregroundColor(self.server_running ? Color.red : Color.gray)
						}

						Spacer().frame(width: 30)

						Button(action: {
							if !self.server_running && (Const.getWiFiAddress() != nil || self.override_no_wifi) {
								self.loadServer()
							}
							UserDefaults.standard.setValue(true, forKey: "has_run")
						}) {
							Image(systemName: "play.fill")
								.font(.system(size: self.font_size))
								.foregroundColor(self.server_running ? Color.gray : Color.green)
						}

					}.padding(10)

					Spacer()

					HStack {
						Button(action: {
							self.view_settings.toggle()
						}) {
							Image(systemName: "gear")
								.font(.system(size: self.font_size))
						}.sheet(isPresented: $view_settings) {
							SettingsView()
						}
					}.padding(10)
				}.padding(8)

			}.background(LinearGradient(gradient: Gradient(colors: [Color("BeginningBlur"), Color("EndBlur")]), startPoint: .topLeading, endPoint: .bottomTrailing))
			.cornerRadius(16)
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.stroke(Color(UIColor.tertiarySystemBackground), lineWidth: 2)
			)
			.shadow(radius: 7)

		}.padding(.init(top: 6, leading: 10, bottom: 6, trailing: 10))
		.frame(height: 80)
		.background(Color(UIColor.secondarySystemBackground))
	}

	var body: some View {

		let port_binding = Binding<String>(get: {
			self.port
		}, set: {
			let new_port = $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().count > 3 ?
				$0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined() :
				UserDefaults.standard.object(forKey: "port") as? String ?? "8741" /// To make sure it's an available port
			self.port = new_port
			UserDefaults.standard.setValue(new_port, forKey: "port")
		})

		let pass_binding = Binding<String>(get: {
			self.password
		}, set: {
			self.password = $0
			UserDefaults.standard.setValue($0, forKey: "password")
		})

		return VStack {
			HStack {
				Text("SMServer")
					.font(.largeTitle)

				Spacer()
			}.padding()
			.padding(.top, 14)

			if Const.getWiFiAddress() != nil || override_no_wifi {
				Text("Visit http\(secure ? "s" : "")://\(Const.getWiFiAddress() ?? self.getHostname()):\(port) in your browser to view your messages!")
					.font(Font.custom("smallTitle", size: 22))
					.padding()
			} else {
				Text("Please connect to wifi to operate the server.")
					.font(Font.custom("smallTitle", size: 22))
					.padding()
			}

			Spacer().frame(height: 20)

			HStack {
				Text("To learn more, visit")
					.font(.headline)
				Text("the github repo")
					.font(.headline)
					.foregroundColor(.blue)
					.onTapGesture {
						let url = URL.init(string: "https://github.com/iandwelker/smserver")
						guard let github_url = url, UIApplication.shared.canOpenURL(github_url) else { return }
						UIApplication.shared.open(github_url)
					}
			}

			GeometryReader { geo in

				ZStack {
					RoundedRectangle(cornerRadius: 10)
						.padding(.init(top: geo.size.width * 0.15, leading: geo.size.width * 0.15, bottom: geo.size.width * 0.15, trailing: geo.size.width * 0.15))
						.foregroundColor(Color(UIColor.tertiarySystemBackground))
						.shadow(radius: 7)
						.frame(height: 300)

					VStack {
						HStack {
							Text("Port")

							Spacer().frame(width: 10)

							TextField("Port number", text: port_binding)
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.disableAutocorrection(true)

						}.frame(width: geo.size.width * self.geo_width)

						HStack {
							Text("Pass")

							Spacer().frame(width: 10)

							TextField("Password", text: pass_binding)
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.disableAutocorrection(true)
						}.frame(width: geo.size.width * self.geo_width)

						Spacer().frame(height: 30)

						HStack {

							Button(action: {
								let picker = DocPicker(
									supportedTypes: ["public.text"],
									onPick: { url in
										do {
											try FileManager.default.copyItem(at: url, to: Const.custom_css_path)
										} catch {
											Const.log("Couldn't move custom css", debug: self.debug, warning: true)
										}
									}
								)
								UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
							}) {
								Text("Set custom CSS")
									.padding(8)
									.background(Color.blue)
									.cornerRadius(40)
									.foregroundColor(Color.white)
							}

							Spacer().frame(width: 10)

							Button(action: {
								do {
									try FileManager.default.removeItem(at: Const.custom_css_path)
									Const.log("Removed custom css file", debug: self.debug)
								} catch {
									Const.log("Failed to remove custom css file", debug: self.debug, warning: true)
								}
							}) {
								Image(systemName: "trash")
									.padding(12)
									.background(Color.blue)
									.cornerRadius(40)
									.foregroundColor(Color.white)
							}
						}
					}
				}
			}

			Spacer()

			if UserDefaults.standard.object(forKey: "has_run") == nil {
				HStack {
					Text("Tap the arrow to start!")
						.font(.callout)
					Spacer()
				}.padding(.leading)
			} else {
				Spacer().frame(height: 20)
			}

			Spacer()

			bottom_bar /// created above

		}.onAppear() {
			self.loadFuncs()
		}
		.background(Color(UIColor.secondarySystemBackground))
		.edgesIgnoringSafeArea(.all)
		.alert(isPresented: $show_oseven_update, content: {
			Alert(title: Text("0.7.0 Update"), message: Text("SMServer was recently updated to version 0.7.0. In this update, many parts of the API were rewritten to be easier to use and more robust.\n\nIf you are using the API of this app in any way outside of the built-in web interface, I would recommend that you check the API documentation (link in Settings) and verify that what you've made is still compatible"), dismissButton: Alert.Button.default(Text("OK"), action: { self.show_oseven_update = false }))
		})
	}
}

class DocPicker: UIDocumentPickerViewController, UIDocumentPickerDelegate {
	/// Document Picker

	private let onPick: (URL) -> ()

	init(supportedTypes: [String], onPick: @escaping (URL) -> Void) {
		self.onPick = onPick

		super.init(documentTypes: supportedTypes, in: .open)

		allowsMultipleSelection = false
		delegate = self
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		onPick(urls.first ?? URL(fileURLWithPath: ""))
	}
}

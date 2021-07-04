import Foundation
import SwiftUI
import Photos

struct ContentView: View {
	let server = ServerDelegate()
	let settings = Settings.shared()
	let geo_width: CGFloat = 0.6
	let font_size: CGFloat = 25

	@State var view_settings: Bool = false
	@State var server_running: Bool = false
	@State var show_picker: Bool = false
	@State var ip_address: String = ""
	@State var show_failed_start: Bool = false
	@State var failed_start_msg: String = ""
	@State var actively_loading: Bool = false
	@State var socket_state: SocketState = .Disconnected(false)

	@State var lower_msg: String = ""
	@State var main_msg: String = Const.getWiFiAddress() != nil || Settings.shared().override_no_wifi ? "Click the start button to run the server!" : "Please connect to wifi to operate the server."

	func loadServer() {
		/// This starts the server at port $port_num
		Const.log("Attempting to load server and socket...")

		// so that the main view can refresh and show a loading indicator
		setLoading {
			let running = server.startServers()

			Const.log(running.0 ? "Successfully started server and socket" : "Failed to start server and socket: \(running.1)", warning: !running.0)

			server_running = running.0
			if !server_running {
				failed_start_msg = running.1
				show_failed_start = true
			} else {
				main_msg = visitMsg()
			}
		}
	}

	func visitMsg() -> String {
		if server_running {
			return "Visit http\(settings.is_secure ? "s" : "")://\(ip_address):\(settings.server_port) in your browser to view your messages!"
		}

		if Const.getWiFiAddress() != nil || settings.override_no_wifi {
			return "Click the start button to run the server!"
		}

		return "Please connect to wifi to operate the server"
	}

	func stopServers() {
		if self.server_running {
			setLoading {
				self.server.stopServers()
				self.server_running = false

				main_msg = visitMsg()
			}
		}
	}

	func enteredBackground() {
		/// Just waits a minute and then kills the app if you disabled backgrounding. A not graceful way of doing what the system does automatically
		if !settings.background || !self.server.isRunning() {
			Const.log("sceneDidEnterBackground, starting kill timer")
			DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: {
				if UIApplication.shared.applicationState == .background {
					exit(0)
				}
			})
		}
	}

	func loadFuncs() {
		/// All the functions that run on scene load

		if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
			PHPhotoLibrary.requestAuthorization({ auth in
				if auth != PHAuthorizationStatus.authorized {
					Const.log("App is not authorized to view photos. Please grant access.", warning: true)
				}
			})
		}

		if settings.start_on_load && (Const.getWiFiAddress() != nil || settings.override_no_wifi)  {
			loadServer()
		}

		NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "ianwelker.smserver.system.config.network_change"), object: nil, queue: nil, using: { notification in
			self.ip_address = Const.getWiFiAddress() ?? "\(self.getHostname()).local"
			self.server_running = server.isRunning()
		})

		self.ip_address = Const.getWiFiAddress() ?? "\(self.getHostname()).local"

		NotificationCenter.default.addObserver(forName: Notification.Name(Const.ss_changed_notification), object: nil, queue: nil, using: socketStateChanged(notification:))
	}

	func reloadVars() {
		self.server.reloadVars()
	}

	func getHostname() -> String {
		let hnp: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>.allocate(capacity: 255)
		var _ = gethostname(hnp, 100)

		let new_str = String.init(cString: hnp!)

		free(hnp)
		return new_str
	}

	func socketStateChanged(notification: Notification) {
		guard let state = notification.object as? SocketState else {
			return
		}

		socket_state = state

		self.actively_loading = false

		switch state {
			case .Disconnected(let retry):
				lower_msg = "Socket disconnected"
				if retry {
					setLoading {
						server.starscream.setSocketState(new_state: .Reconnecting)
						if server.starscream.registerAndConnect() {
							server.starscream.setSocketState(new_state: .Connected)
						} else {
							server.starscream.setSocketState(new_state: .FailedConnect)
						}
					}
				}
			case .Connecting:
				lower_msg = "Socket connecting..."
				self.actively_loading = true
			case .Connected:
				if let id = settings.remote_id {
					lower_msg = "Your remote id is \(id)"
				} else {
					lower_msg = "Unable to get remote id; restart to try again"
				}
			case .Reconnecting:
				lower_msg = "Socket reconnecting..."
			case .FailedConnect:
				lower_msg = "Socket failed to connect"
		}
	}

	func setLoading(_ block: @escaping () -> Void) {
		self.actively_loading = true
		DispatchQueue.global().async {
			block()
			self.actively_loading = false
		}
	}

	var bottom_bar: some View { /// just to break up the code
		HStack {
			HStack {
				HStack {
					HStack {
						Button(action: self.reloadVars) {
							Image(systemName: "goforward")
								.font(.system(size: self.font_size))
								.foregroundColor(Color.purple)
						}

						Spacer().frame(width: 24)

						Button(action: stopServers) {
							Image(systemName: "stop.fill")
								.font(.system(size: self.font_size))
								.foregroundColor(self.server_running ? Color.red : Color.gray)
						}

						Spacer().frame(width: 30)

						if self.actively_loading {
							ActivityIndicator(isAnimating: $actively_loading, style: .medium)
						} else {
							Button(action: {
								if !self.server_running && (Const.getWiFiAddress() != nil || self.settings.override_no_wifi) {
									self.loadServer()
								}
								UserDefaults.standard.setValue(true, forKey: "has_run")
							}) {
								Image(systemName: "play.fill")
									.font(.system(size: self.font_size))
									.foregroundColor(self.server_running ? Color.gray : Color.green)
							}
						}

					}.padding(10)

					Spacer()

					HStack {
						Button(action: { self.view_settings.toggle() }) {
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
			String(self.settings.server_port)
		}, set: {
			let new_port = $0.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
			if let num = Int(new_port) {
				self.settings.server_port = num
				UserDefaults.standard.setValue(num, forKey: "port")
			}
		})

		let pass_binding = Binding<String>(get: {
			self.settings.password
		}, set: {
			self.settings.password = $0
			UserDefaults.standard.setValue($0, forKey: "password")
		})

		return VStack {
			HStack {
				Text("SMServer")
					.font(.largeTitle)

				Spacer()
			}.padding()
			.padding(.top, 14)

			Text(verbatim: self.main_msg)
				.font(Font.custom("smallTitle", size: 22))
				.padding()

			Text(lower_msg)
				.font(Font.custom("smallerTitle", size: 20))
				.padding()

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
											Const.log("Couldn't move custom css", warning: true)
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
									Const.log("Removed custom css file")
								} catch {
									Const.log("Failed to remove custom css file", warning: true)
								}
							}) {
								Image(systemName: "trash")
									.padding(8)
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
		.alert(isPresented: $show_failed_start, content: {
			Alert(title: Text("Failed to start"), message: Text(self.failed_start_msg), dismissButton: Alert.Button.default(Text("OK"), action: { self.show_failed_start = false }))
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

struct ActivityIndicator: UIViewRepresentable {
	@Binding var isAnimating: Bool
	let style: UIActivityIndicatorView.Style

	func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
		return UIActivityIndicatorView(style: style)
	}

	func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
		isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
	}
}

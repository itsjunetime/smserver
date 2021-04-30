import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		return true
	}

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

@main
struct MainApp {
	static func main() throws {
		if CommandLine.argc > 1 {
			MainApp.setUpSignalHandlers()

			var token: Int32 = 0
			memorystatus_control(UInt32(5), getpid(), 500, &token, 0)

			let sets = Settings.shared()
			sets.parseArgs()

			guard !sets.show_help else {
				print(Const.help_string)
				exit(0)
			}

			guard let ip_address = Const.getWiFiAddress() else {
				print("Sorry, it appears you aren't connected to the internet. Please connect and try again")
				exit(1)
			}
			let server_string = "http\(sets.is_secure ? "s" : "")://\(ip_address):\(sets.server_port)"
			print("\(Const.col)34m==>\(Const.col)0;1m Starting servers at \(server_string)...\(Const.col)0m")

			let server = ServerDelegate()
			let success = server.startServers()

			if success {
				print("\(Const.col)34m==>\(Const.col)0m Success!\(Const.col)1m")
				if sets.cli_background {
					print("\(Const.col)0mServer will now run in the background until you kill it")
				} else {
					print("Enter 'q' at any time to quit SMServer\(Const.col)0m")
				}
			} else {
				print("\(Const.col)31;1mERROR:\(Const.col)0m SMServer failed to start.\(sets.debug ? "" : " Try again with the \(Const.col)1m--debug\(Const.col)0m flag to see more details")")
				exit(1)
			}

			if sets.cli_background {
				dispatchMain()
			} else {
				while let input = readLine() {
					if input == "q" { exit(0) }
				}
			}

		} else {
			_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, nil)
		}
	}

	static func setUpSignalHandlers() {
		signal(SIGTTIN, SIG_IGN)

		let sigttin = DispatchSource.makeSignalSource(signal: SIGTTIN, queue: .main)
		sigttin.setEventHandler(handler: {
			print("Got SIGTTIN... sucks")
		})

		sigttin.resume()
	}
}

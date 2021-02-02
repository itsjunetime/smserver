import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}
}

@main
struct MainApp {
	static func main() throws {
		if CommandLine.argc > 1 {
			MainApp.setUpSignalHandlers()
			
			let sets = Settings.shared()
			sets.parseArgs()
			
			guard !sets.show_help else {
				print(Const.help_string)
				exit(0)
			}
			
			print("\(Const.col)34m==>\(Const.col)0;1m Starting servers...\(Const.col)0m")
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
				print("\(Const.col)31;1mERROR:\(Const.col)0m SMServer failed to start. Please try again with the \(Const.col)1m--debug\(Const.col)0m flag.")
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

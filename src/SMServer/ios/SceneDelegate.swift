import UIKit
import SwiftUI
import os

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	let contentView = ContentView()

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		if let windowScene = scene as? UIWindowScene {
			let window = UIWindow(windowScene: windowScene)
			window.rootViewController = UIHostingController(rootView: contentView)
			self.window = window
			window.makeKeyAndVisible()
		}
	}

	func sceneDidDisconnect(_ scene: UIScene) {}

	func sceneDidBecomeActive(_ scene: UIScene) {}

	func sceneWillResignActive(_ scene: UIScene) {}

	func sceneWillEnterForeground(_ scene: UIScene) {}

	func sceneDidEnterBackground(_ scene: UIScene) {
		if !(UserDefaults.standard.object(forKey: "backgrounding_enabled") as? Bool ?? true) {
			contentView.enteredBackground()
		}
	}
}


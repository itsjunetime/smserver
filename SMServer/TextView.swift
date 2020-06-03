//
//  TextView.swift
//  SMServer
//
//  Created by Ian Welker on 6/2/20.
//  Copyright © 2020 Ian Welker. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class MessagesViewController : UIViewController, MFMessageComposeViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func topMostController() -> UIViewController {
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    @IBAction func sendNewIMessage(_ sender: Any, bodyAndAddress: [String]) {
        //So IBActions can only have 2 args at most? So guess we'll just use an array for body adn adrress
        let messageVC = MFMessageComposeViewController()
        print("Body: " + bodyAndAddress[0])
        print("Addres: " + bodyAndAddress[1])
        messageVC.body = bodyAndAddress[0]
        messageVC.recipients = [bodyAndAddress[1]]
        messageVC.messageComposeDelegate = self
        DispatchQueue.main.async {
            self.topMostController().present(messageVC, animated: true, completion: nil)
        }
        
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            print("Message was cancelled")
            self.topMostController().dismiss(animated: true, completion: nil)
        case .failed:
            print("Message failed")
            self.topMostController().dismiss(animated: true, completion: nil)
        case .sent:
            print("Message was sent")
            self.topMostController().dismiss(animated: true, completion: nil)
        default:
            self.topMostController().dismiss(animated: true, completion: nil)
        }
    }
}

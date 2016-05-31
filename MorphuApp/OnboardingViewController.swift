//
//  onboardingViewController.swift
//  Morphu
//
//  Created by Dylan Wight on 5/5/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import UIKit
//import FBSDKLoginKit

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func facebookButton(sender: AnyObject) {
        activityIndicator.startAnimating()
        API.sharedInstance.connectWithFacebook(self, callback: facebookCallback)
    }
    
    func facebookCallback(valid: Bool) {

        if valid {
            API.sharedInstance.checkLoggedIn(loginCallback)
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    func loginCallback(loginValid: Bool) {
        activityIndicator.stopAnimating()
        if loginValid {
            self.performSegueWithIdentifier("toMainController", sender: self)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    @IBAction func backToOnBoarding(segue: UIStoryboardSegue) {}
}
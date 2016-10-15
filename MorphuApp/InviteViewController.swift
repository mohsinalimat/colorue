//
//  GroupTableViewController.swift
//  Colorue
//
//  Created by Dylan Wight on 4/21/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import UIKit
import Contacts
import MessageUI
import Firebase

class InviteViewController: UITableViewController, MFMessageComposeViewControllerDelegate, APIDelagate {
    
    let api = API.sharedInstance
    
    let tintColor = blueColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = backgroundColor
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        api.delagate = self
        self.tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return api.getContacts().count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "InviteCell")! as! InviteCell
        let contact = api.getContacts()[(indexPath as NSIndexPath).row]
        cell.contactName.text = contact.name
        return cell
    }
    
    fileprivate func sendInvite(_ contact: Contact) {

        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()

            

            controller.body = "\(api.getActiveUser().username) invited you to join the Colorue beta test\nwww.facebook.com/colorueApp/"

            controller.recipients = [contact.getPhoneNumber()!]
            controller.messageComposeDelegate = self
            self.resignFirstResponder()

            self.present(controller, animated: true, completion: {
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.sendInvite(api.getContacts()[(indexPath as NSIndexPath).row])
    }

    
    // MARK: MFMessageComposeViewControllerDelegate Methods
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
        switch result {
        case .sent:
            FIRAnalytics.logEvent(withName: "inviteSent", parameters: [:])
        default:
            break
        }
    }
    
    // MARK: APIDelagate Methods
    
    func refresh() {
        self.tableView.reloadData()
    }
}

//
//  PromptViewController.swift
//  Colorue
//
//  Created by Dylan Wight on 8/6/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//


import UIKit
import Firebase

class PromptsViewController: UITableViewController, CommentCellDelagate {
    
    let api = API.sharedInstance
    
    var tintColor = redColor
    
    private var textInputCell: TextInputCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = backgroundColor
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return api.getPrompts().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell")! as! CommentCell
        
        let prompt = api.getPrompts()[indexPath.row]
        cell.username.text = prompt.user.username
        cell.profileImage.image = prompt.user.profileImage
        cell.timeStamp.text = prompt.getTimeSinceSent()
        cell.commentText.text = prompt.text
        
        cell.userButton.tag = indexPath.row
        
//        cell.comment = comment
        cell.delagate = self
        
        return cell
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("WriteCommentCell")! as! TextInputCell
        cell.delagate = self
        
        let separatorU = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 0.5))
        separatorU.backgroundColor = UIColor.lightGrayColor()
        cell.addSubview(separatorU)
        
        cell.textField?.tintColor = self.tintColor
        cell.submitButton?.setTitleColor(self.tintColor, forState: .Normal)
        
        cell.textField?.delegate = cell
        cell.textField?.placeholder = "Create prompt..."

        self.textInputCell = cell
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PromptViewController,
            let row = tableView.indexPathForSelectedRow?.row {
            controller.tintColor = self.tintColor
            controller.prompt = api.getPrompts()[row]
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return  UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    

    
    @IBAction func pullRefresh(sender: UIRefreshControl) {
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
}

extension PromptsViewController: TextInputCellDelagate {
    func submit(text: String) {
        api.createPrompt(text)
        self.textInputCell?.textField?.text = ""
        FIRAnalytics.logEventWithName("submitPrompt", parameters: [:])
        self.tableView.reloadData()
    }
}
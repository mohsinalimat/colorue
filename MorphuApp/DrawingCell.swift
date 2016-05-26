//
//  InboxDrawingCell.swift
//  Morphu
//
//  Created by Dylan Wight on 4/8/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import UIKit

class DrawingCell: UITableViewCell, DrawingDelagate {
    
    let api = API.sharedInstance
    var delagate: DrawingCellDelagate?
    var drawing: Drawing?
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var creator: UILabel!
    @IBOutlet weak var drawingImage: UIImageView!
    @IBOutlet weak var timeCreated: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCount: UIButton!
    @IBOutlet weak var likes: UILabel!
    @IBOutlet weak var commentCount: UILabel!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    @IBAction func upload(sender: UIButton) {
        delagate?.upload(self)
    }
    
    @IBAction func like(sender: UIButton) {
        if !(drawing?.liked(api.getActiveUser()))! {
            sender.selected = true
            delagate?.like(self)
        } else {
            sender.selected = false
            delagate?.unlike(self)
        }
    }
    
    @IBAction func viewLikes(sender: UIButton) {
        delagate?.viewLikes(self)
    }
    
    @IBAction func viewComments(sender: UIButton) {
        delagate?.viewComments(self)
    }
    
    func setProgress(progress: Float) {
        progressBar.setProgress(progress, animated: true)
    }
    
    func imageLoaded(image: UIImage) {
        self.progressBar.hidden = true
        self.drawingImage.image = image
        self.delagate?.refresh()
    }
}
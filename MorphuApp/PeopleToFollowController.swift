//
//  PeopleToFollowController.swift
//  Colorue
//
//  Created by Dylan Wight on 6/29/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import Foundation

class PeopleToFollowController: UserListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated:true)
        self.users =  api.getSuggustedUsers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
}

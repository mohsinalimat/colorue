//
//  SearchViewController.swift
//  Canvix
//
//  Created by Dylan Wight on 6/4/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import UIKit

class SearchViewController: UITableViewController, UISearchBarDelegate {
    
    let searchBar = UISearchBar(frame: CGRectMake(0, 0, 340, 20))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        searchBar.placeholder = "Search coming soon..."
        
        let leftNavBarButton = UIBarButtonItem(customView:searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
        
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = backgroundColor
        
        searchBar.delegate = self
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        searchBar.frame = CGRectMake(0, 0, 340, 20)


        self.navigationItem.setRightBarButtonItem(nil, animated: true)
    }


    func cancelBarButtonItemClicked(sender: UIBarButtonItem) {
        self.searchBarCancelButtonClicked(self.searchBar)
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        searchBar.frame = CGRectMake(0, 0, 285, 20)
        
        
        let cancelSearchBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(SearchViewController.cancelBarButtonItemClicked(_:)))
        self.navigationItem.setRightBarButtonItem(cancelSearchBarButtonItem, animated: true)
        return true
    }
}
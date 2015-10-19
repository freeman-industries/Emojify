//
//  PhotosGrid.swift
//  emojify
//
//  Created by Nabil Freeman on 11/10/2015.
//  Copyright © 2015 Freeman Industries. All rights reserved.
//

import UIKit
import Photos
import Foundation

class SharingTableController : UITableViewController {
    
    //empty model for our TableView. we'll initialize and use this later on.
    var dataObject: [(Dictionary<String, Any>)] = [
        [
            "label": "💾 Save to Photos",
            "interacted": false
        ],
        [
            "label": "🔁 Emojify another image!",
            "interacted": false
        ],
        [
            "label": "🔗 WhatsApp",
            "interacted": false
        ],
        [
            "label": "🔗 WeChat",
            "interacted": false
        ],
        [
            "label": "🔗 Instagram",
            "interacted": false
        ],
        [
            "label": "🔗 Twitter",
            "interacted": false
        ],
        [
            "label": "🔗 Facebook",
            "interacted": false
        ],
        
    ]
    
    var savedPhoto = false
    
    
    //i have to do this because I don't understand AutoLayout. Fuck autolayout.
    func setControlContainerSize(notification: NSNotification) {
//        return
        
        var frame: CGRect = self.view.frame
        
        let screenHeight = UIScreen.mainScreen().bounds.height
        let delta = notification.object as! CGFloat
        
        print("Setting control container size...")
        //        print(screenHeight - delta)
        
        frame.size.height = screenHeight - delta
        frame.size.width = UIScreen.mainScreen().bounds.width
        
        self.view.frame = frame
        self.tableView?.frame = frame
    }
    
    func scrollToTopControlContainer(notification: NSNotification) {
        self.tableView?.setContentOffset(CGPointMake(0, 0), animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\nhello world bitches (SharingTable)")
        
        //messenger bus stuff for setControlContainerSize
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "setControlContainerSize:",
            name: "setControlContainerSize",
            object: nil
        )
        
        //messenger bus stuff to scroll to top
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "scrollToTopControlContainer:",
            name: "scrollToTopControlContainer",
            object: nil
        )
        
        self.tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0)
        self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        self.tableView?.reloadData()
        
        print("\nEnd of SharingTable viewDidLoad")
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataObject.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let text = dataObject[indexPath.row]["label"] as! String
        let interacted = dataObject[indexPath.row]["interacted"] as! Bool
        
        let cell = tableView.dequeueReusableCellWithIdentifier("row", forIndexPath: indexPath) as! SharingTableCellController
        
        cell.clipsToBounds = true
        
        let font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        
        cell.textLabel!.text = text
        cell.textLabel!.font = font
        cell.textLabel!.textColor = UIColor(hex: 0xFFFFFF)
        
        let separator = cell.separator
        cell.separatorWidth.constant = UIScreen.mainScreen().bounds.width
        
        if(interacted){
            cell.textLabel!.alpha = 0.5
            separator.alpha = 0
            cell.userInteractionEnabled = false
        } else {
            cell.textLabel!.alpha = 1
            separator.alpha = 1
            cell.userInteractionEnabled = true
        }
        
        let selectedView = UIView()
        selectedView.frame = cell.frame
        selectedView.backgroundColor = UIColor.blackColor()
        
        cell.selectedBackgroundView = selectedView
        
        
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(indexPath.row == 0){
            dataObject[indexPath.row]["label"] = "✅ Saved to Photos"
            dataObject[indexPath.row]["interacted"] = true
        }
        
        let timeout = NSTimeInterval(0.1)
        self.performSelector("reloadData", withObject: nil, afterDelay: timeout)
        
    }
    
    func reloadData(){
        print("hello")
        self.tableView?.reloadData()
    }
    
}

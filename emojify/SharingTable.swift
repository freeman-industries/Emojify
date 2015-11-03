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
    var dataObject: [(Dictionary<String, Any>)] = []
    
    func resetDataObject(){
        dataObject = [
            [
                "label": "💾  Save to Photos",
                "interacted": false
            ],
            [
                "label": "🔁  Emojify another image!",
                "interacted": false
            ],
            [
                "label": "📲  Share to...",
                "interacted": false
            ]
        ]
        
        self.tableView?.reloadData()
    }
    
    var savedPhoto = false
    
    
    //i have to do this because I don't understand AutoLayout. Fuck autolayout.
    func setControlContainerSize(notification: NSNotification) {
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
    
    func scrollToTopControlContainer() {
        self.tableView?.setContentOffset(CGPointMake(0, 0), animated: true)
    }
    
    func resetSharingTable(notification: NSNotification) {
        resetDataObject()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\nhello world (SharingTable)")
        
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
            selector: "scrollToTopControlContainer",
            name: "scrollToTopControlContainer",
            object: nil
        )
        
        //messenger bus stuff to scroll to top
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "resetDataObject",
            name: "restartUserJourney",
            object: nil
        )
        
        //messenger bus stuff to scroll to top
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "resetDataObject",
            name: "photoChanged",
            object: nil
        )
        
        
        
        var bottomMargin: CGFloat = 45
        
        //iOS 8 seems to treat footers and collectionviews differently from iOS 9. This is a patch to support iOS 8.
        let iOS90 = NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)
        if( !NSProcessInfo().isOperatingSystemAtLeastVersion(iOS90) ){
            bottomMargin = 90
        }
        
        
        self.tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomMargin, right: 0)
        self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        
        resetDataObject()
        
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
        
        let font = UIFont.systemFontOfSize(18, weight: UIFontWeightSemibold)
        
        cell.textLabel!.text = text
        cell.textLabel!.font = font
        cell.textLabel!.textColor = UIColor(hex: 0xFFFFFF)
        
        let separator = cell.separator
        cell.separatorWidth.constant = UIScreen.mainScreen().bounds.width
        
        if(interacted){
            cell.textLabel!.alpha = 0.5
            cell.userInteractionEnabled = false
        } else {
            cell.textLabel!.alpha = 1
            cell.userInteractionEnabled = true
        }
        
        let selectedView = UIView()
        selectedView.frame = cell.frame
        selectedView.backgroundColor = UIColor(hex: 0x4000FF)
        
        if(indexPath.row == 0){
            separator.alpha = 0
        } else {
            separator.alpha = 1
            
            let selectedSeparator = UIView()
            
            selectedSeparator.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.size.width, height: 1)
            selectedSeparator.backgroundColor = UIColor.blackColor()
            
            selectedView.addSubview(selectedSeparator)
        }
        
        cell.selectedBackgroundView = selectedView
        
        
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(indexPath.row == 0){
            dataObject[indexPath.row]["label"] = "✅  Saved to Photos"
            dataObject[indexPath.row]["interacted"] = true
            
            NSNotificationCenter.defaultCenter().postNotificationName("savePhoto", object: nil)
        }
        
        if(indexPath.row == 1){
            NSNotificationCenter.defaultCenter().postNotificationName("restartUserJourney", object: nil)
        }
        
        if(indexPath.row == 2){
            NSNotificationCenter.defaultCenter().postNotificationName("sharingDialog", object: nil)
        }
        
        let timeout = NSTimeInterval(0.05)
        self.performSelector("reloadData", withObject: nil, afterDelay: timeout)
        
    }
    
    func reloadData(){
        self.tableView?.reloadData()
    }
    
}

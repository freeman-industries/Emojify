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

class EmojiGridController : UICollectionViewController {
    
    //ray wenderleich's tutorial put this up here. it's just an ID from the Storyboard and it references the UICollectionViewCells.
    let reuseIdentifier = "emojiCell"
    
    //empty model for our CollectionView. we'll initialize and use this later on.
    var dataObject: [String] = []
    
    
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
        self.collectionView?.frame = frame
    }
    
    func scrollToTopControlContainer() {
        self.collectionView?.setContentOffset(CGPointMake(0, 0), animated: true)
    }
    
    
    
    func restartUserJourney() {
        scrollToTopControlContainer()
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\nhello world (EmojiGrid)")
        
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
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "restartUserJourney",
            name: "restartUserJourney",
            object: nil
        )
        
        //read emoji file and populate model.
        dispatch_async(dispatch_get_main_queue(), {self.getEmojiData()})
        
        print("\nEnd of EmojiGrid viewDidLoad")
    }
    
    
    func getEmojiData(){
        
        var pathName = "";
        
        let iOS90 = NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)
        let iOS91 = NSOperatingSystemVersion(majorVersion: 9, minorVersion: 1, patchVersion: 0)
        
        if(NSProcessInfo().isOperatingSystemAtLeastVersion(iOS91)){
            //iOS 9.1
            pathName = "emoji-iOS-9.1"
        } else if(NSProcessInfo().isOperatingSystemAtLeastVersion(iOS90)){
            //iOS 9.0
            pathName = "emoji-iOS-9.0"
        } else {
            //iOS 8.2
            pathName = "emoji-iOS-8.2"
        }
        
        print("Loading emoji file with path name " + pathName)
        
        let path = NSBundle.mainBundle().pathForResource(pathName, ofType: "txt")
        
        do{
            //TODO iOS 9 doesn't support some of these characters. how can i make this per-device compatible??
            
            let emojiFile = try String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
            
            //from stack overflow, splits string characters into array
//            let characters = Array(emojiFile.characters)
            let characters = emojiFile.componentsSeparatedByString(":::::")
//            let characters = emojiFile.characters.split{$0 == ":::::"}.map(String.init)
            
            characters.forEach({
                dataObject.append(String($0))
            })
            
            self.collectionView?.reloadData()
            
        } catch {
            print("Error reading file.")
        }
    }

    
    
    
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataObject.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //make a cell. we extended UICollectionViewCell to access the imageView.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! EmojiCellController
        
        //set up the imageView for this cell.
        let emoji = dataObject[indexPath.row]
        
        cell.emojiLabel.text = emoji
        
        let fontSize = floor(cell.bounds.width * 0.8)
        
//        print("Emoji font size: \(fontSize)")
        
        cell.emojiLabel.font = UIFont.systemFontOfSize(fontSize)
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        print("\nSelected:")
//        print(indexPath.row)
        
        NSNotificationCenter.defaultCenter().postNotificationName("emojiChosen", object: dataObject[indexPath.row])
        
    }
    
}


extension EmojiGridController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            
            //edge insets of 10 on each side. 10x2 = 20.
            let width = screenSize.width - 20
            
            var modifier: CGFloat = 9
            
            if(screenSize.width == 320){
                modifier = 8
            }
            
            let gapSpacing: CGFloat = 5
            
            let gapSpacingTotal = (modifier - 1) * gapSpacing
            let cellSize = (width - gapSpacingTotal) / modifier
            
            return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            
            var bottomMargin: CGFloat = 10
            
            //iOS 8 seems to treat footers and collectionviews differently from iOS 9. This is a patch to support iOS 8.
            let iOS90 = NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)
            if( !NSProcessInfo().isOperatingSystemAtLeastVersion(iOS90) ){
                bottomMargin = 56
            }
            
            
            
            return UIEdgeInsets(top: 10, left: 10, bottom: bottomMargin, right: 10)

    }
}
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\nhello world bitches (EmojiGrid)")
        
        //messenger bus stuff for setControlContainerSize
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "setControlContainerSize:",
            name: "setControlContainerSize",
            object: nil
        )
        
        //read emoji file and populate model.
        dispatch_async(dispatch_get_main_queue(), {self.getEmojiData()})
        
        print("\nEnd of EmojiGrid viewDidLoad")
    }
    
    
    func getEmojiData(){
        let path = NSBundle.mainBundle().pathForResource("allEmoji", ofType: "txt")
        
        do{
            //TODO iOS 9 doesn't support some of these characters. how can i make this per-device compatible??
            
            let emojiFile = try String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
            
            //from stack overflow, splits string characters into array
            let characters = Array(emojiFile.characters)
            
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
            
            return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    }
}
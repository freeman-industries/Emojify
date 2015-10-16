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

class PhotosGridController : UICollectionViewController {
    
    //ray wenderleich's tutorial put this up here. it's just an ID from the Storyboard and it references the UICollectionViewCells.
    let reuseIdentifier = "photoCell"
    
    //empty model for our CollectionView. we'll initialize and use this later on.
    var dataObject:[(Dictionary<String, Any>)?] = []
    
    
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
        
        print("\nhello world bitches (PhotosGrid)")
        
        //messenger bus stuff for setControlContainerSize
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "setControlContainerSize:",
            name: "setControlContainerSize",
            object: nil
        )
        
        //This is where we ask for permission for the user's photo library. it would be nice to move this to the splash screen.
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            requestAuthorizationHandler(PHPhotoLibrary.authorizationStatus())
        }
        else
        {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
        
        print("\nEnd of PhotosGrid viewDidLoad")
    }
    
    
    func populatePhotoGrid() {
        
        self.collectionView?.allowsMultipleSelection = false
        
        let phOptions = PHFetchOptions()
        
        phOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: phOptions)
        
        let count = assets.count
        
        print("\nNumber of images in camera roll...")
        print(count)
        
        //all the code for the rest of this function is about initing the model for our collectionView.
        dataObject = [(Dictionary<String, Any>)?](count: count, repeatedValue: nil)
        
        for(var i = 0; i < count; i++){
            
            //we need to scope this within the for loop - i is unreliable. now we can access it safely from the requestImage callback below.
            let assetIndex = i
            
            //asset is scoped similarly to assetIndex.
            let asset = assets[i] as! PHAsset
            
            //we need to initialize our dictionaries now. note that all image data is currently blank.
            self.dataObject[assetIndex] = [
                "asset": asset as PHAsset,
                "thumbnail": nil as UIImage?,
                "selected": false as Bool,
            ]
            
            //the dataObject is basically a model for the CollectionView. we need to set selected to be true for the first asset, and the view will render it as such.
            //we also (just once) need to manually send the first image to ViewController to display in the big screen.
            if(assetIndex == 0){
                self.dataObject[assetIndex]?["selected"] = true
                self.sendHighResPhoto(assetIndex, asset: asset)
            }
            
            //we have to explicitly tell collectionView to re-render. we do it like this.
            self.collectionView?.reloadData()
        }
        
        
    }
    
    
    func requestAuthorizationHandler(status: PHAuthorizationStatus)
    {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            //it's really important that we run the getPhoto stuff asynchronously. a lot of data is being handled in them and we don't want the thread to lock up.
            //if we don't do this, the launch screen will appear for ages which sucks.
            dispatch_async(dispatch_get_main_queue(), {self.populatePhotoGrid()})
            
        }
    }
    
    
    func sendHighResPhoto(index: Int, asset: PHAsset){
        //this function communicates with our parent View (where the big square image is), retrieves a photo from PHImageManager and then sends it an image to display.

        let options:PHImageRequestOptions = PHImageRequestOptions()
        options.synchronous = false
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        let screenScale = UIScreen.mainScreen().scale
        
        let targetDimension = screenWidth * screenScale
        
//        print("Requesting image of size \(targetDimension) to be displayed.")
        
        PHImageManager.defaultManager().requestImageForAsset(
            asset,
            targetSize: CGSize(width: targetDimension, height: targetDimension),
            contentMode: PHImageContentMode.AspectFill,
            options: options,
            resultHandler: { (result, info) in
                
                //returns UIImage result
                NSNotificationCenter.defaultCenter().postNotificationName("imageChosen", object: result as UIImage!)
                
                
            }
        )
        
    }
    
    
    
    
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataObject.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //make a cell. we extended UICollectionViewCell to access the imageView.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotosCellController
        
        //set up the imageView for this cell.
        
        let thumbnail = dataObject[indexPath.row]?["thumbnail"] as? UIImage
        if(thumbnail !== nil){
            //we've already downloaded a thumbnail for this asset! let's display it.
            cell.imageView.image = thumbnail
            
            
        } else {
            //we need to retreive a thumbnail for this asset...
            let asset = dataObject[indexPath.row]?["asset"] as! PHAsset
            
            let options:PHImageRequestOptions = PHImageRequestOptions()
            options.synchronous = false
            
            
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            let screenScale = UIScreen.mainScreen().scale
            
            let modifier: CGFloat = 4
            let gapSpacing: CGFloat = 1
            
            let gapSpacingTotal = (modifier - 1) * gapSpacing
            let targetDimension = ((screenSize.width - gapSpacingTotal) / modifier) * screenScale
            
            
            //        print("Requesting thumbnail of size \(targetDimension).")
            
            PHImageManager.defaultManager().requestImageForAsset(
                asset,
                targetSize: CGSize(width: targetDimension, height: targetDimension),
                contentMode: PHImageContentMode.AspectFill,
                options: options,
                resultHandler: { (result, info) in
                    
                    //returns UIImage result
                    
                    //this will initially show us a tiny thumbnail, and then will overwrite with a bigger image asynchronously. pretty cool.
                    cell.imageView.image = result as UIImage!
                    
                    //let's store it for next time too.
                    self.dataObject[indexPath.row]?["thumbnail"] = result as UIImage!
                    
                    
                }
            )
        }
        
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        
        
        //check data model to see if this cell needs to be styled as selected or deselected.
        let selected = dataObject[indexPath.row]?["selected"]
        
        if(selected as? Bool == true){
            cell.selected = true
            cell.layer.borderWidth = 2
            cell.layer.borderColor = UIColor(hex: 0x4000FF).CGColor
            cell.imageView.alpha = 0.7
        } else {
            cell.selected = false
            cell.layer.borderWidth = 0
            cell.layer.borderColor = UIColor(hex: 0x4000FF).CGColor
            cell.imageView.alpha = 1
        }
        
//        print("reloading!!!")
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        print("\nSelected:")
//        print(indexPath.row)
        
        if(dataObject[indexPath.row]?["selected"] as? Bool == true){
            print("This tile is already selected. Ignoring...")
            return
        }
        
        for(var i = 0; i < dataObject.count; i++){
            dataObject[i]?["selected"] = false
        }
        
        dataObject[indexPath.row]?["selected"] = true
        
        self.collectionView?.reloadData()
        
        sendHighResPhoto(indexPath.row, asset: dataObject[indexPath.row]?["asset"] as! PHAsset)
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        print("\nDeselected:")
//        print(indexPath.row)
        
        dataObject[indexPath.row]?["selected"] = false
        
        self.collectionView?.reloadData()
    }
    
    
}

extension PhotosGridController: PHPhotoLibraryChangeObserver
{
    func photoLibraryDidChange(changeInstance: PHChange)
    {
        
        //TODO PRETTY SURE THIS IS IMPORTANT
        
        
        
        //        guard let assets = assets else
        //        {
        //            return
        //        }
        //
        //        if let changeDetails = changeInstance.changeDetailsForFetchResult(assets) where uiCreated
        //        {
        //            PhotoBrowser.executeInMainQueue{ self.assets = changeDetails.fetchResultAfterChanges }
        //        }
    }
}

extension PhotosGridController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            
            let modifier: CGFloat = 4
            let gapSpacing: CGFloat = 1
            
            let gapSpacingTotal = (modifier - 1) * gapSpacing
            let cellSize = (screenSize.width - gapSpacingTotal) / modifier
            
            return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    }
}
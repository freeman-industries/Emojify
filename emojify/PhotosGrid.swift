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
    
    @IBOutlet var photosGrid: UICollectionView!
    
    let reuseIdentifier = "photoCell"
    
    var dataObject:[(Dictionary<String, Any>)?] = []
    
    
    
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
        
        print("hello world bitches (PhotosGrid)")
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "setControlContainerSize:",
            name: "setControlContainerSize",
            object: nil
        )
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            requestAuthorizationHandler(PHPhotoLibrary.authorizationStatus())
        }
        else
        {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
        
        print("End of PhotosGrid viewDidLoad")
    }
    
    
    func populatePhotoGrid() {
        
        self.collectionView?.allowsMultipleSelection = false
        
        let phOptions = PHFetchOptions()
        
        phOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: phOptions)
        
        let count = assets.count
        
        print("\nNumber of images in camera roll...")
        print(count)
        
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
//                "fullsize": nil as UIImage?,
                "selected": false as Bool,
            ]
            
            //the dataObject is basically a model for the CollectionView. we need to set selected to be true for the first asset, and the view will render it as such.
            //we also (just once) need to manually send the first image to ViewController to display in the big screen.
            if(assetIndex == 0){
                self.dataObject[assetIndex]?["selected"] = true
                self.sendHighResPhoto(assetIndex, asset: asset)
            }
            
            self.collectionView?.reloadData()
        }
        
//        for(var i = 0; i < count; i++){
//        
//            //we need to scope this within the for loop - i is unreliable. now we can access it safely from the requestImage callback below.
//            let assetIndex = i
//            
//            //asset is scoped similarly to assetIndex.
//            let asset = assets[i] as! PHAsset
//        
//            let options:PHImageRequestOptions = PHImageRequestOptions()
//            options.synchronous = false
//            
//            let screenWidth = UIScreen.mainScreen().bounds.width
//            let screenScale = UIScreen.mainScreen().scale
//            let thumbnailWidth = (screenWidth / 4) - 1.5
//            
//            let targetDimension = thumbnailWidth * screenScale
//            
////            print("Requesting thumbnail of size \(targetDimension).")
//            
//            PHImageManager.defaultManager().requestImageForAsset(
//                asset,
//                targetSize: CGSize(width: targetDimension, height: targetDimension),
//                contentMode: PHImageContentMode.AspectFill,
//                options: options,
//                resultHandler: { (result, info) in
//                
//                    //returns UIImage result
//                    
//                    //this will initially show us a thumbnail, and then will overwrite with a big image asynchronously. pretty cool.
//                    if((self.dataObject[assetIndex]) != nil){
//                        self.dataObject[assetIndex]?["thumbnail"] = result as UIImage!
//                    } else {
//                        self.dataObject[assetIndex] = [
//                            "asset": asset as PHAsset,
//                            "thumbnail": result as UIImage!,
//                            "fullsize": nil as UIImage?,
//                            "selected": false as Bool,
//                        ]
//                    }
//                    
//                    if(assetIndex == 0){
//                        self.dataObject[assetIndex]?["selected"] = true
//                        self.sendHighResPhoto(assetIndex, asset: asset)
//                    }
//                    
//                    self.collectionView?.reloadData()
//                    
//                }
//            )
//        
//        }
        
    }
    
    
    
    
    
    func requestAuthorizationHandler(status: PHAuthorizationStatus)
    {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            //to run it in the main queue, whatever that means...
            dispatch_async(dispatch_get_main_queue(), {self.populatePhotoGrid()})
            
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
            
            let screenWidth = UIScreen.mainScreen().bounds.width
            let screenScale = UIScreen.mainScreen().scale
            let thumbnailWidth = (screenWidth / 4) - 1.5
            
            let targetDimension = thumbnailWidth * screenScale
            
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
        print("\nSelected:")
        print(indexPath.row)
        
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
        print("\nDeselected:")
        print(indexPath.row)
        
        dataObject[indexPath.row]?["selected"] = false
        
        self.collectionView?.reloadData()
    }
    
    
    func sendHighResPhoto(index: Int, asset: PHAsset){
        
        let existingAsset = self.dataObject[index]?["fullsize"] as? UIImage
        
//        if(existingAsset !== nil){
//            NSNotificationCenter.defaultCenter().postNotificationName("imageChosen", object: existingAsset as UIImage!)
//            
//            
//        } else {
            let options:PHImageRequestOptions = PHImageRequestOptions()
            options.synchronous = false
            
            let screenWidth = UIScreen.mainScreen().bounds.width
            let screenScale = UIScreen.mainScreen().scale
            
            let targetDimension = screenWidth * screenScale
            
            print("Requesting image of size \(targetDimension) to be displayed.")
            
            PHImageManager.defaultManager().requestImageForAsset(
                asset,
                targetSize: CGSize(width: targetDimension, height: targetDimension),
                contentMode: PHImageContentMode.AspectFill,
                options: options,
                resultHandler: { (result, info) in
                    
                    //returns UIImage result
                    NSNotificationCenter.defaultCenter().postNotificationName("imageChosen", object: result as UIImage!)
//                    self.dataObject[index]?["fullsize"] = result as UIImage!
                    
                    
                }
            )
            
            
//        }
        
    }
    
}

extension PhotosGridController: PHPhotoLibraryChangeObserver
{
    func photoLibraryDidChange(changeInstance: PHChange)
    {
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
            
            return CGSize(width: (screenSize.width / modifier) - 1.5, height: (screenSize.width / modifier) - 1.5)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    }
}
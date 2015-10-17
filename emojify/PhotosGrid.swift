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
import AVFoundation

class PhotosGridController : UICollectionViewController {
    
    //empty model for our CollectionView. we'll initialize and use this later on.
    var dataObject: [(Dictionary<String, Any>)?] = []
    //raw asset data from PHPhotoLibrary. used to compare for changes in photoLibraryDidChange
    var assets = PHFetchResult()
    
    //for a live camera preview in the Photos Grid.
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    //for when a user taps the camera icon.
    var imagePicker: UIImagePickerController!
    
    
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
    
    func scrollToTopControlContainer(notification: NSNotification) {
        self.collectionView?.setContentOffset(CGPointMake(0, 0), animated: true)
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
        
        //messenger bus stuff to scroll to top
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "scrollToTopControlContainer:",
            name: "scrollToTopControlContainer",
            object: nil
        )
        
        //messenger bus stuff to turn camera on and off
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "checkActiveControlView:",
            name: "activeControlView",
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
        
        //set up our camera input for the photos grid live preview.
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    
                    if(captureDevice != nil){
                        
                        do{
                            let input = try AVCaptureDeviceInput(device: captureDevice)
                        
                            captureSession.addInput(input)
                            
                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                            previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill;
                        } catch {
                            print("av error...")
                        }
                    }
                    
                }
            }
        }
        
        //get imagePicker ready for if user taps camera.
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        
        print("\nEnd of PhotosGrid viewDidLoad")
    }
    
    
    func populatePhotoGrid() {
        
        self.collectionView?.allowsMultipleSelection = false
        
        let phOptions = PHFetchOptions()
        
        phOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        assets = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: phOptions)
        
        populateDataModel()
    }
    
    func populateDataModel() {
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
            
        }
        
        //we have to explicitly tell collectionView to re-render. we do it like this.
        self.collectionView?.reloadData()
        
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
        
        PHImageManager.defaultManager().requestImageForAsset(
            asset,
            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            contentMode: PHImageContentMode.Default,
            options: options,
            resultHandler: { (result, info) in
                
                var arr: [AnyObject] = []
                
                arr.append(result as UIImage!)
                arr.append(asset as PHAsset!)
                
                //returns UIImage result
                NSNotificationCenter.defaultCenter().postNotificationName("imageChosen", object: arr)
                
                
            }
        )
        
    }

    
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataObject.count + 1
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //if this is the first cell in the entire collection, no thumbnail necessary. this is going to be a live camera preview.
        if(indexPath.row == 0){
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cameraCell", forIndexPath: indexPath) as! PhotosCameraCellController
            
            
            
            //check for existence of camera. if not. we need to end this function quickly.
            if( !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) ){
                cell.label.text = "📷⚠️"
                cell.label.font = UIFont.systemFontOfSize(floor(cell.bounds.width * 0.3))
                return cell
            }
            //no camera... return here. probs just simulator but maybe also broken iOS devices. i don't discriminate.
            
            if( !(cell.layer.sublayers?[0] is AVCaptureVideoPreviewLayer) ){
                cell.layer.insertSublayer(previewLayer!, atIndex: 0)
                previewLayer?.frame = cell.layer.frame
            }
            
            //add sexy blur effect to cell
            if( !(cell.subviews[0] is UIVisualEffectView) ){
                
                if !UIAccessibilityIsReduceTransparencyEnabled() {
                    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    //always fill the view
                    blurEffectView.frame = cell.bounds
                    //blurEffectView.alpha = 0.6
                    
                    blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                    
                    //insert this right at the bottom of our tabBar, z-index 0
                    cell.insertSubview(blurEffectView, atIndex: 0)
                }
                
            }
            
            //set label font size for nice emoji icon
            cell.label.font = UIFont.systemFontOfSize(floor(cell.bounds.width * 0.5))
            
            
            return cell
        }
        
        //END CAMERA STUFF
        
        
        
        //so it's not the first cell in the photos grid. that means it's an image thumbnail...
        
        //make a cell. we extended UICollectionViewCell to access the imageView.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotosCellController
        
        
        //ok, it's an image thumbnail!!!
        
        //check data model to see if this cell needs to be styled as selected or deselected.
        let selected = dataObject[indexPath.row - 1]?["selected"]
        
        if(selected as? Bool == true){
            cell.selected = true
            cell.layer.borderWidth = 2
            cell.layer.borderColor = UIColor(hex: 0x4000FF).CGColor
            cell.imageView.alpha = 0.8
        } else {
            cell.selected = false
            cell.layer.borderWidth = 0
            cell.layer.borderColor = UIColor(hex: 0x4000FF).CGColor
            cell.imageView.alpha = 1
        }
        
        
        //set up the imageView for this cell.
        let thumbnail = dataObject[indexPath.row - 1]?["thumbnail"] as? UIImage
        if(thumbnail !== nil){
            //we've already downloaded a thumbnail for this asset! let's display it.
            cell.imageView.image = thumbnail
            
            
        } else {
            //we need to retreive a thumbnail for this asset...
            let asset = dataObject[indexPath.row - 1]?["asset"] as! PHAsset
            
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
                    self.dataObject[indexPath.row - 1]?["thumbnail"] = result as UIImage!
                    
                    
                }
            )
        }
        
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill

        
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if(indexPath.row == 0){
            if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
                return true
            } else {
                return false
            }
        }
        
        return true
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        print("\nSelected:")
//        print(indexPath.row)
        
        if(indexPath.row == 0){
            //open camera here.
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            presentViewController(imagePicker, animated: true, completion: nil)
            return
        }
        
        if(dataObject[indexPath.row - 1]?["selected"] as? Bool == true){
//            print("This tile is already selected. Ignoring...")
            return
        }
        
        for(var i = 0; i < dataObject.count; i++){
            dataObject[i]?["selected"] = false
        }
        
        dataObject[indexPath.row - 1]?["selected"] = true
        
        self.collectionView?.reloadData()
        
        sendHighResPhoto(indexPath.row - 1, asset: dataObject[indexPath.row - 1]?["asset"] as! PHAsset)
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        print("\nDeselected:")
//        print(indexPath.row)
        
        if(indexPath.row == 0){
            return
        }
        
        dataObject[indexPath.row - 1]?["selected"] = false
        
        self.collectionView?.reloadData()
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if(indexPath.row == 0){
            let visiblePaths = self.collectionView?.indexPathsForVisibleItems()
            
            if(!visiblePaths!.contains(indexPath)){
                toggleCaptureSession(false)
            }
            
        }
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if(indexPath.row == 0){
            toggleCaptureSession(true)
        }
    }
    
    
    func toggleCaptureSession(state: Bool){
        if(state){
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0), {
//                print("activating camera...")
                self.captureSession.startRunning()
            })
        } else {
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0), {
//                print("halting camera...")
                self.captureSession.stopRunning()
            })
        }
    }
    
    
    func checkActiveControlView(notification: NSNotification){
        let active = notification.object as! CGFloat
        
        if(active == 1){
            let visiblePaths = self.collectionView?.indexPathsForVisibleItems()
            
            if(visiblePaths!.contains(NSIndexPath(forRow: 0, inSection: 0))){
                toggleCaptureSession(true)
            }
        } else {
            toggleCaptureSession(false)
        }
    }
    
    
}

extension PhotosGridController: PHPhotoLibraryChangeObserver
{
    func photoLibraryDidChange(changeInstance: PHChange)
    {
        
        //here we pass in our raw assets object and ask PHPhotoryLibrary to check for any image changes. We got an alert that something has changed...
        let changeDetails = changeInstance.changeDetailsForFetchResult(assets)
        let newAssets = changeDetails?.fetchResultAfterChanges
        
        //it would appear that this function fires quite a few times and probably updates things like metadata separately to the photos. therefore sometimes this fires, and the changes are apparently nil.
        if(newAssets == nil){
//            print("Caught a nil value for newAssets, so I'm returning.")
            return
        }
        
        //update the photo model
        dispatch_async(dispatch_get_main_queue(), {
            self.assets = newAssets!
            self.populateDataModel()
        })
        
        
    }
}

extension PhotosGridController : UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        
        //Save it to the camera roll
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
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
//
//  ViewController.swift
//  emojify
//
//  Created by Nabil Freeman on 08/10/2015.
//  Copyright © 2015 Freeman Industries. All rights reserved.
//

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex:Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }
}

import UIKit
import Photos

class ViewController: UIViewController {
    
    
    
    
    let screenSize: CGRect = UIScreen.mainScreen().bounds
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var photoGrid: UICollectionView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("hello world bitches")
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add styling and correct metrics to our view...
        let navbarFont = UIFont.systemFontOfSize(18, weight: UIFontWeightHeavy)
        
        self.view.backgroundColor = UIColor(hex: 0x4000FF)
        
        navBar.translucent = false
        navBar.barTintColor = UIColor(hex: 0x4000FF)
        navBar.titleTextAttributes = [NSFontAttributeName : navbarFont, NSForegroundColorAttributeName : UIColor(hex: 0xFFFFFF)]
        
//        imagePicker.navigationBar.translucent = false
//        imagePicker.navigationBar.barTintColor = UIColor(hex: 0x4000FF)
//        imagePicker.navigationBar.tintColor = UIColor(hex: 0xFFFFFF)
//        imagePicker.navigationBar.titleTextAttributes = [NSFontAttributeName : navbarFont, NSForegroundColorAttributeName : UIColor(hex: 0xFFFFFF)]
//        
//        imageContainer.clipsToBounds = true
//        
//        imagePicker.delegate = self
        
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            populatePhotoGrid()
        }
        else
        {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
//    let imagePicker = UIImagePickerController()
//
//    @IBAction func loadImage(sender: AnyObject) {
//        imagePicker.allowsEditing = false
//        imagePicker.sourceType = .PhotoLibrary
//        
//        presentViewController(imagePicker, animated: true, completion: nil)
//    }
//    
//    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
//        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            imageView.contentMode = .ScaleAspectFill
//            imageView.image = pickedImage
//            imageView.clipsToBounds = true
//            
//            //remove all emoji
//            imageContainer.subviews.forEach({
//                if($0 is UIImageView){
//                    return
//                }
//                
//                $0.removeFromSuperview()
//            })
//            emojiSelected = true
//            activeEmoji = UIButton()
//        }
//        
//        dismissViewControllerAnimated(true, completion: nil)
//    }
    
    
    
    //TODO I have forced emojiSelected to always be true. I want people to be able to position the background photo as well - current it crops to a square. I need to make the behaviour like Instagram - fill to square but people can manipulate the photo to include more or less, rotate etc.
    
    var activeEmoji = UIView()
    var emojiSelected = true
    
    func emojiTap(sender: UIButton!){
        
        if(activeEmoji.subviews.count > 0){
            activeEmoji.subviews[0].layer.removeAllAnimations()
        }
        
        if(sender.superview! == activeEmoji){
            activeEmoji = UIView()
            return
        }
        
        activeEmoji = sender.superview!
        emojiSelected = true
        
        
        sender.transform = CGAffineTransformRotate(sender.transform, -0.12)
        
        UIView.animateWithDuration(
            0.1,
            delay: 0,
            options: [UIViewAnimationOptions.Repeat, UIViewAnimationOptions.Autoreverse, UIViewAnimationOptions.CurveEaseInOut],
            animations: {
                sender.transform = CGAffineTransformRotate(sender.transform, 0.24)
            },
            completion: {(complete: Bool) in
                sender.transform = CGAffineTransformIdentity
                return
            }
        )
        
    }
    
    
    @IBAction func addEmoji(sender: UIButton) {
        
        let str = sender.titleLabel?.text ?? "Error... 😱"
        
        let emojiFrame = UIView(frame: CGRectMake(0,0,80,80))
        emojiFrame.userInteractionEnabled = false
        emojiFrame.center = imageContainer.center
        
        let emoji = UIButton(frame: CGRectMake(0,0,80,80))
        
        emoji.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
        
        let emojiFont = UIFont.systemFontOfSize(80)
        emoji.titleLabel!.font = emojiFont
        emoji.setTitle(str, forState: .Normal)
        emoji.addTarget(self, action: "emojiTap:", forControlEvents: UIControlEvents.TouchUpInside)
        
        emojiFrame.addSubview(emoji)
        imageContainer.addSubview(emojiFrame)
        
        emojiTap(emoji)
    }
    
    
    
    // touch functions.
    
    @IBAction func touchPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(self.view)
        
        if(emojiSelected == false){
            imageView.center = CGPoint(x:imageView.center.x + translation.x,
                y:imageView.center.y + translation.y)
        } else {
            activeEmoji.center = CGPoint(x:activeEmoji.center.x + translation.x,
                y:activeEmoji.center.y + translation.y)
        }
        
        sender.setTranslation(CGPointZero, inView: self.view)
    }
    
    
    @IBAction func touchPinch(sender: UIPinchGestureRecognizer) {

        if(emojiSelected == false){
            imageView.transform = CGAffineTransformScale(imageView.transform, sender.scale, sender.scale)
        } else {
            activeEmoji.transform = CGAffineTransformScale(activeEmoji.transform, sender.scale, sender.scale)
        }
        
        sender.scale = 1
    }
    
    
    @IBAction func touchRotate(sender: UIRotationGestureRecognizer) {

        if(emojiSelected == false){
            imageView.transform = CGAffineTransformRotate(imageView.transform, sender.rotation)
        } else {
            activeEmoji.transform = CGAffineTransformRotate(activeEmoji.transform, sender.rotation)
        }
        
        sender.rotation = 0
    }
    
    
    @IBAction func touchTap(sender: UITapGestureRecognizer) {
        print(sender.locationInView(sender.view))
        
        imageContainer.subviews.forEach({
            if($0 is UIImageView){
                return
            }
            
            if($0.subviews.count == 0){
                return
            }
            
            if(CGRectContainsPoint($0.frame, sender.locationInView(sender.view))){
                let button : UIButton = $0.subviews[0] as! UIButton
                
                emojiTap(button)
            }
        })
    }
    
    
    
    
    @IBAction func savePhoto(sender: UIButton) {
        //Create the UIImage
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(imageContainer.frame.size, false, scale)
        
        imageContainer.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //Save it to the camera roll
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    
    
    
    
    
    func populatePhotoGrid() {
        
        let assets = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: nil)
        
        let i = 1
        
//        for(var i = 0; i < assets.count; i++){
        
            let asset = assets[i] as! PHAsset
            
            let options:PHImageRequestOptions = PHImageRequestOptions()
            options.synchronous = true
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.FastFormat
            
            PHImageManager.defaultManager().requestImageForAsset(
                asset,
                targetSize: CGSize(width: CGFloat(1200), height: CGFloat(1200)),
                contentMode: PHImageContentMode.AspectFill,
                options: nil,
                resultHandler: { (result, _) in
                    let image = UIImageView()
                    let cell = UICollectionViewCell()
                    
                    self.imageView.image = result
                    
//                    image.contentMode = .ScaleAspectFill
//                    image.image = result
//                    image.clipsToBounds = true
                    
                    cell.addSubview(image)
                    
                    self.photoGrid.addSubview(cell)
                }
            )

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
    
    
}


extension ViewController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }
}


extension ViewController: PHPhotoLibraryChangeObserver
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


extension VieWController : UICollectionViewDataSource
{
    
    //1
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    //2
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    //3
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        cell.backgroundColor = UIColor.blackColor()
        // Configure the cell
        return cell
    }
}
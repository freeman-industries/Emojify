//
//  ViewController.swift
//  emojify
//
//  Created by Nabil Freeman on 08/10/2015.
//  Copyright © 2015 Freeman Industries. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    
    
    //SECTION: VARIABLES AND STUFF
    
    
    let screenSize: CGRect = UIScreen.mainScreen().bounds
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    
    
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageContainerLeft: NSLayoutConstraint!
    @IBOutlet weak var imageContainerRight: NSLayoutConstraint!
    
    
    
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var controlsContainerLeft: NSLayoutConstraint!
    @IBOutlet weak var controlsContainerWidth: NSLayoutConstraint!
    
    @IBOutlet weak var tabBar: UIView!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\nhello world bitches (ViewController)")
        
        self.view.layoutIfNeeded()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add styling and correct metrics to our view...
        let navbarFont = UIFont.systemFontOfSize(18, weight: UIFontWeightHeavy)
        
        navBar.translucent = false
        navBar.barTintColor = UIColor(hex: 0x4000FF)
        navBar.titleTextAttributes = [NSFontAttributeName : navbarFont, NSForegroundColorAttributeName : UIColor(hex: 0xFFFFFF)]
        
        if(screenSize.height < 568){
            imageContainerLeft.constant = 40
            imageContainerRight.constant = 40
        }
        
        
        //calculate the size of everything on screen apart from controls container.
        //+2 +2 for the margin on either side of the control container
        let allElementsApartFromControls = imageContainer.bounds.height + navBar.bounds.height + 1
        
        print(allElementsApartFromControls, imageContainer.bounds.height, imageContainer.bounds.width, navBar.bounds.height)
        
        //TODO maybe only 2 sections rather than 3? Share screen might be a full page change.
        controlsContainerWidth.constant = screenSize.width * 3
        //TODO this property should be animated based on app state. / 2 so we can see two states at the same time.
        controlsContainerLeft.constant = 0
        
        //we need to generate layout constraints for width to make our controls view look good.
        controlsContainer.subviews.forEach({

            let viewWidth = NSLayoutConstraint (item: $0,
                attribute: NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: nil,
                attribute: NSLayoutAttribute.NotAnAttribute,
                multiplier: 1,
                constant: screenSize.width)
            controlsContainer.addConstraint(viewWidth)
            
        })
        
        //...and now let's set the width of our Tab Bar buttons.
        //we need to generate layout constraints for width to make our controls view look good.
        tabBar.subviews.forEach({
            
            let viewWidth = NSLayoutConstraint (item: $0,
                attribute: NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: nil,
                attribute: NSLayoutAttribute.NotAnAttribute,
                multiplier: 1,
                constant: screenSize.width / 3)
            tabBar.addConstraint(viewWidth)
            
        })
        
        //one sided border-top with some neat CGRect stuff.
        let border = UIView()
        border.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 1)
        border.backgroundColor = UIColor(hex: 0x000000)
        
        tabBar.addSubview(border)
        
        //add sexy blur effect to tabBar.
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            tabBar.backgroundColor = UIColor.clearColor()
            
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = tabBar.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            //insert this right at the bottom of our tabBar, z-index 0
            tabBar.insertSubview(blurEffectView, atIndex: 0)
        } 
        else {
            //dummy view that's life purpose is to occupy space 0 in the tab bar. so our button logic works correctly.
            let dummyView = UIView()
            dummyView.frame = tabBar.bounds
            dummyView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            dummyView.backgroundColor = UIColor(hex: 0x000000)
            
            tabBar.insertSubview(dummyView, atIndex: 0)
        }
        
        //let's initialize our tab bar by auto selecting the first button.
        setControlView(tabBar.subviews[1] as! UIButton)
        
        //END TAB BAR STYLING
        
        //cross view communication.
        NSNotificationCenter.defaultCenter().postNotificationName("setControlContainerSize", object: allElementsApartFromControls)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "setImage:",
            name: "imageChosen",
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "addEmoji:",
            name: "emojiChosen",
            object: nil
        )
        
        
        
        print("\nend of viewDidLoad in ViewController")
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    var activeControlView: CGFloat = 0
    
    @IBAction func setControlView(sender: UIButton) {
        //extract tag from the button data and parse it as a CGFloat
        let tag = CGFloat(sender.tag)
        
        //the below stuff is for cool button background effect.
        tabBar.subviews.forEach({
            if($0 !== sender && $0 is UIButton){
                ($0 as! UIButton).backgroundColor = UIColor.clearColor()
            }
        })
        
        sender.backgroundColor = UIColor(hex: 0x4000FF)
        
        activeControlView = tag
        NSNotificationCenter.defaultCenter().postNotificationName("activeControlView", object: activeControlView)
        
        self.view.layoutIfNeeded()
        
        //end cool button background effect.
        //now we're gonna animate the view the user selected into position!
        //in Storyboard we set a tag on each button, 1, 2, 3 depending on the screen. with clever maths we figure out the distance to move by.
        
        controlsContainerLeft.constant = screenSize.width - (screenSize.width * tag)
        
        //need to think of a better way to express the below. TODO
        if(activeControlView == 1){
            imageScrollView.userInteractionEnabled = true
            
            for(var i = imageContainer.subviews.count - 1; i >= 0; i--){
                
                if(imageContainer.subviews[i] is UIScrollView){
                    continue
                }
                
                imageContainer.subviews[i].alpha = 0.7
            }
        } else {
            imageScrollView.userInteractionEnabled = false
            
            for(var i = imageContainer.subviews.count - 1; i >= 0; i--){
                
                if(imageContainer.subviews[i] is UIScrollView){
                    continue
                }
                
                imageContainer.subviews[i].alpha = 1
            }
        }
        
        
        
        UIView.animateWithDuration(
            0.3,
            delay:0,
            options: [UIViewAnimationOptions.CurveEaseOut],
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: {finished in })
        
        deselectAllEmoji()
    }
    
    
    
    
    
    
    
    func setImage(notification: NSNotification){
        
//        print(notification)
        
        let object = notification.object as! [AnyObject]
        
        var image = object[0] as! UIImage
        let asset = object[1] as! PHAsset
        
        
        let pxwidth = CGFloat(asset.pixelWidth)
        let pxheight = CGFloat(asset.pixelHeight)
        
        
        //PHPhotoLibrary has sent us a temporary thumbnail image. we don't want any jumpy stuff in the scrollView so we are going to resize it to exactly the same pixels as the expected image.
        if( (image.size.width != pxwidth) && (image.size.height != pxheight) ){
            //we use 1.0 instead of 0.0 because 0.0 causes the device to scale from pixels to points. we don't wanna do that.
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(pxwidth, pxheight), false, 1.0)
            image.drawInRect(
                CGRectMake(
                    0,
                    0,
                    pxwidth,
                    pxheight
                )
            )
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        
        
        imageView.image = image
        
        
        imageScrollView.delegate = self
        
        if(pxwidth > pxheight){
            imageScrollView.minimumZoomScale = imageScrollView.bounds.size.height / pxheight
        } else {
            imageScrollView.minimumZoomScale = imageScrollView.bounds.size.width / pxwidth
        }
        
        imageScrollView.zoomScale = imageScrollView.minimumZoomScale
        
        
        let offsetX = imageScrollView.contentSize.width - (imageScrollView.bounds.size.width / 2);
        let offsetY = imageScrollView.contentSize.height - (imageScrollView.bounds.size.height / 2);
        
        
//        imageScrollView.contentOffset = CGPointMake(offsetX, offsetY)
        
        //remove all emoji
        imageContainer.subviews.forEach({
            if($0 is UIScrollView){
                return
            }
        
            $0.removeFromSuperview()
        })
        
        emojiSelected = false
        activeEmoji = UIButton()
    }
    
    
    
    
    
    //SECTION: IMAGE VIEW - EMOJI EDITING ETC
    
    //TODO I have forced emojiSelected to always be true. I want people to be able to position the background photo as well - current it crops to a square. I need to make the behaviour like Instagram - fill to square but people can manipulate the photo to include more or less, rotate etc.
    
    var activeEmoji = UIView()
    var emojiSelected = false
    
    func deselectAllEmoji(){
        
        if(activeEmoji.subviews.count > 0){
            activeEmoji.subviews[0].layer.removeAllAnimations()
        }
        
        activeEmoji = UIView()
        emojiSelected = false

    }
    
    func emojiTap(sender: UIButton!){
        
        if(activeEmoji.subviews.count > 0){
            activeEmoji.subviews[0].layer.removeAllAnimations()
        }
        
        if(sender.superview! == activeEmoji){
            activeEmoji = UIView()
            emojiSelected = false
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
    
    
    func addEmoji(notification: NSNotification) {
        
        let str = notification.object as! String
        
        let emojiFrame = UIView(frame: CGRectMake(0,0,90,90))
        emojiFrame.userInteractionEnabled = false
        emojiFrame.center = imageContainer.center
        
        var centerCoords = CGPointMake(imageContainer.frame.size.width / 2, imageContainer.frame.size.height / 2)
        let twoPercent = imageContainer.frame.size.width / 50
    
        //let's slightly randomize the center of the emoji. this way it's clear if somebody has added two emoji instead of one.
        //we use the twopercent variable as the offset.
        var random = arc4random_uniform(10) + 1
        
        if(random > 5){
            centerCoords.x = centerCoords.x + (twoPercent * (CGFloat(random) / 10))
        } else {
            centerCoords.x = centerCoords.x - (twoPercent * (CGFloat(random) / 10))
        }
        
        random = arc4random_uniform(10) + 1
        
        if(random > 5){
            centerCoords.y = centerCoords.y + (twoPercent * (CGFloat(random) / 10))
        } else {
            centerCoords.y = centerCoords.y - (twoPercent * (CGFloat(random) / 10))
        }
        
        emojiFrame.center = centerCoords
        
        
        
        let emoji = UIButton(frame: CGRectMake(0,0,90,90))
        
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
//            imageView.center = CGPoint(x:imageView.center.x + translation.x, y:imageView.center.y + translation.y)
        } else {
            activeEmoji.center = CGPoint(x:activeEmoji.center.x + translation.x,
                y:activeEmoji.center.y + translation.y)
        }
        
        sender.setTranslation(CGPointZero, inView: self.view)
    }
    
    
    @IBAction func touchPinch(sender: UIPinchGestureRecognizer) {

        if(emojiSelected == false){
//            imageView.transform = CGAffineTransformScale(imageView.transform, sender.scale, sender.scale)
        } else {
            activeEmoji.transform = CGAffineTransformScale(activeEmoji.transform, sender.scale, sender.scale)
        }
        
        sender.scale = 1
    }
    
    
    @IBAction func touchRotate(sender: UIRotationGestureRecognizer) {

        if(emojiSelected == false){
//            imageView.transform = CGAffineTransformRotate(imageView.transform, sender.rotation)
        } else {
            activeEmoji.transform = CGAffineTransformRotate(activeEmoji.transform, sender.rotation)
        }
        
        sender.rotation = 0
    }
    
    
    @IBAction func touchTap(sender: UITapGestureRecognizer) {
        
        if(sender.view is UINavigationBar){
            NSNotificationCenter.defaultCenter().postNotificationName("scrollToTopControlContainer", object: nil)
            return
        }
        
        for(var i = imageContainer.subviews.count - 1; i >= 0; i--){
            
            if(imageContainer.subviews[i] is UIScrollView){
                continue
            }
            
            if(imageContainer.subviews[i].subviews.count == 0){
                continue
            }
            
            let point = sender.locationInView(sender.view)
            let newPoint = sender.view?.convertPoint(point, toView: imageContainer.subviews[i])
            
            if(CGRectContainsPoint(imageContainer.subviews[i].bounds, newPoint!)){
                let button : UIButton = imageContainer.subviews[i].subviews[0] as! UIButton
                
                emojiTap(button)
                
                break
            }
        }
        
    }
    
    
    
    
    
    
    //SECTION: LOAD IN PHOTOS (also saving, probs should move it)
    
    
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
    
    
    
}


//SECTION: EXTENSIONS - important to keep things working.

extension ViewController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if(activeControlView != CGFloat(2)){
            return false
        }
        
        return true
    }
}

extension ViewController: UIScrollViewDelegate
{
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
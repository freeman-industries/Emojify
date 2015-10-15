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

extension NSLayoutConstraint {
    
    override public var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)" //you may print whatever you want here
    }
}

import UIKit
import Photos

class ViewController: UIViewController {
    
    
    
    //SECTION: VARIABLES AND STUFF
    
    
    let screenSize: CGRect = UIScreen.mainScreen().bounds
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var controlsContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("hello world bitches (ViewController)")
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add styling and correct metrics to our view...
        let navbarFont = UIFont.systemFontOfSize(18, weight: UIFontWeightHeavy)
        
        self.view.backgroundColor = UIColor(hex: 0x000000)
        
        navBar.translucent = false
        navBar.barTintColor = UIColor(hex: 0x4000FF)
        navBar.titleTextAttributes = [NSFontAttributeName : navbarFont, NSForegroundColorAttributeName : UIColor(hex: 0xFFFFFF)]
        
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "setImage:",
            name: "imageChosen",
            object: nil
        )
        
        let topHalf = UIScreen.mainScreen().bounds.width + navBar.frame.size.height + 2
        
        NSNotificationCenter.defaultCenter().postNotificationName("setControlContainerSize", object: topHalf)
        
        print("end of viewDidLoad in ViewController")
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    func setImage(notification: NSNotification){
        
//        print(notification)
        
        let image = notification.object as! UIImage
        
        imageView.image = image
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
    }
    
    
    
    
    
    //SECTION: IMAGE VIEW - EMOJI EDITING ETC
    
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
        return true;
    }
}
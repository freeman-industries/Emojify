//
//  ViewController.swift
//  emojify
//
//  Created by Nabil Freeman on 08/10/2015.
//  Copyright © 2015 Freeman Industries. All rights reserved.
//

import UIKit
import Photos

class PermissionsViewController: UIViewController {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var rejectedView: UIView!
    
    
    @IBOutlet weak var fakeAlert: UIView!
    @IBOutlet weak var horizontal: UIView!
    @IBOutlet weak var vertical: UIView!
    
    @IBOutlet weak var finger: UILabel!
    
    var authorizationStatus: [Bool?] = [nil, nil]
    var rejected = false
    var segued = false
    
    override func loadView() {
        super.loadView()
    }
    
    func AVAuthorizationCallback(status: Bool){
        if(status == true){
            authorizationStatus[0] = true
        } else {
            authorizationStatus[0] = false
            
            if(AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Denied || AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Restricted){
                rejected = true
            }
        }
        
        authorizationCallback()
    }
    
    func PHAuthorizationCallback(status: PHAuthorizationStatus){
        if(status == PHAuthorizationStatus.Authorized){
            authorizationStatus[1] = true
        } else {
            authorizationStatus[1] = false
            
            if(PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Denied || PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Restricted) {
                rejected = true
            }
        }
        
        authorizationCallback()
    }
    
    func authorizationCallback(){
        if(authorizationStatus[0] == true && authorizationStatus[1] == true && segued == false){
            dispatch_async(dispatch_get_main_queue(), {
                if (self.isViewLoaded() == true && self.view.window != nil) {
                    self.performSegueWithIdentifier("main", sender: self)
                }
            })
            segued = true
        } else {
            if(authorizationStatus[0] != nil && authorizationStatus[1] != nil){
                if(rejected == false){
                    dispatch_async(dispatch_get_main_queue(), {
                        self.mainView.hidden = false
                        self.mainView.userInteractionEnabled = true
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.mainView.hidden = true
                        self.mainView.userInteractionEnabled = false
                        self.rejectedView.hidden = false
                        self.rejectedView.userInteractionEnabled = true
                    })
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\nhello world bitches (PermissionsViewController)")
        
        fakeAlert.layer.cornerRadius = 15
        fakeAlert.layer.borderColor = UIColor(hex: 0x9690FA).CGColor
        fakeAlert.layer.borderWidth = 1
        
        horizontal.backgroundColor = UIColor(hex: 0x9690FA)
        vertical.backgroundColor = UIColor(hex: 0x9690FA)
        
        
        UIView.animateWithDuration(
            0.6,
            delay: 0,
            options: [UIViewAnimationOptions.Repeat, UIViewAnimationOptions.Autoreverse, UIViewAnimationOptions.CurveEaseOut],
            animations: {
                self.finger.transform = CGAffineTransformTranslate(self.finger.transform, 0, -10)
            },
            completion: {(complete: Bool) in
                self.finger.transform = CGAffineTransformIdentity
                return
            }
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "checkAuthorizationStatus",
            name: "UIApplicationDidBecomeActiveNotification",
            object: nil
        )
        
        print("\nend of viewDidLoad in PermissionsViewController")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        
        segued = false
        
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus(){
        authorizationStatus = [nil, nil]
        
        //This is where we ask for permission for the user's photo library. it would be nice to move this to the splash screen.
        if (PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized) {
            PHAuthorizationCallback(PHPhotoLibrary.authorizationStatus())
        } else {
            PHAuthorizationCallback(PHAuthorizationStatus.NotDetermined)
        }
        
        //ask permission for the camera.
        if(AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Authorized){
            AVAuthorizationCallback(true)
        } else {
            AVAuthorizationCallback(false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func mainButtonTap(sender: UIButton) {
        PHPhotoLibrary.requestAuthorization(PHAuthorizationCallback)
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: AVAuthorizationCallback)
        
        
    }
    
    @IBAction func openSettings(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(
            NSURL(string: UIApplicationOpenSettingsURLString)!
        )
    }
}
//
//  CameraController.swift
//  ExploringMetal_iOS
//
//  Created by Adil Patel on 25/07/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import UIKit
import simd

class CameraController: NSObject, TouchInputDelegate {

    let camera: Camera
    
    let elevationSensitivity: Float = 0.01
    let azimuthSensitivity: Float = -0.01
    let moveSensitivity: Float = 0.025
    
    var fingerRight: UITouch? = nil
    var fingerLeft:  UITouch? = nil
    
    init(camera: Camera) {
        self.camera = camera
        self.camera.movementInputDevice = .touchScreen
    }
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
        
        // Here we assign labels to the fingers first...
        for touch in touches {
            let xLocation = touch.location(in: view).x
            if fingerRight == nil && xLocation > view.bounds.size.width / 2 {
                fingerRight = touch
            } else if fingerLeft == nil && xLocation < view.bounds.size.width / 2 { // Only falls to here if fingerRight isn't nil
                fingerLeft = touch
            }
        }
        // The above will simply ignore the presence of a third (and above touch)
        
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
        
        for touch in touches {

            // Calculating the angles here
            if touch == fingerRight && touch.location(in: view).x > view.bounds.size.width / 2  {
                
                let currentLocation = touch.location(in: view)
                let previousLocation = touch.previousLocation(in: view)
                let diff = currentLocation - previousLocation // The touch displacement
                let dx = Float(diff.x)
                let dy = Float(diff.y)
                
                // The angles added are proportional to these displacement compnents
                camera.azimuth += azimuthSensitivity * dx
                camera.elevation += elevationSensitivity * dy
                
            } else if touch == fingerLeft && touch.location(in: view).x < view.bounds.size.width / 2  {
                // Left finger...
                
                let currentLocation  = touch.location(in: view)
                let previousLocation = touch.previousLocation(in: view)

                // Set the finger displacement in the camera... the velocity itself is computed in Camera
                camera.movingFingerDisplacement = currentLocation - previousLocation
                
            }


        }
        
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {
        
        for touch in touches {
            if touch == fingerRight {
                fingerRight = nil
            } else if touch == fingerLeft {
                fingerLeft = nil
                
            }
        }
        
    }
    
}

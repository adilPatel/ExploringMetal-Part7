//
//  CameraController.swift
//  ExploringMetal_macOS
//
//  Created by Adil Patel on 27/07/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Cocoa
import simd

class CameraController: NSObject, MacInputDelegate {

    let camera: Camera
    
    // The mouse position in screen coordinates
    var mousePosition: CGPoint? = nil
    
    // Determines how quickly the camera rotates in response to a mouse event
    let azimuthSensitivity: Float = -0.01
    
    // Determines how quickly the camera rotates in response to a mouse event
    let elevationSensitivity: Float = -0.01
    
    
    init(camera: Camera) {
        self.camera = camera
        self.camera.movementInputDevice = .keyboard
    }
    
    func keyDown(key: UInt16) {
        
        // Ignore the callback if the key is already pressed
        if !camera.keyIsPressed {
            camera.currentKeyPressed = key
            camera.keyIsPressed = true
        }
        
    }
    
    func keyUp(key: UInt16) {
        camera.keyIsPressed = false
        camera.currentKeyPressed = nil
    }
    
    func mouseMoved(position: CGPoint) {
        
        if let currentPosition = mousePosition {
            let dx = Float(position.x - currentPosition.x)
            let dy = Float(position.y - currentPosition.y)
            camera.azimuth   += azimuthSensitivity   * dx
            camera.elevation += elevationSensitivity * dy
        }
        mousePosition = position
        
    }
    
    
}

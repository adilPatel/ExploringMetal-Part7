//
//  Camera.swift
//  ExploringMetal
//
//  Created by Adil Patel on 05/07/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import simd

#if os(OSX)
import Cocoa
#else
import UIKit
#endif

class Camera: NSObject, AnimatedObject {

    var movementInputDevice: InputDevices!
    
    // Keep this as a 3D vector as we're incrementing
    var position: float3
    
    // The azimuth angle of the camera w.r.t. the -z axis
    var azimuth: Float = 0.0
    
    // The elevation angle of the camera w.r.t. the y axis
    var elevation: Float = 0.0
    
    // Fetched by the scene using it in its update loop
    var currentViewMatrix = matrix_identity_float4x4
    
    // The projection matrix is handled by the camera
    var projectionMatrix: matrix_float4x4
    
    var rotationMatrix = matrix_identity_float4x4
    
    
    // Keyboard controls
    // If a key is pressed already
    var keyIsPressed = false
    
    // The current key which is pressed ... nil if nothing is pressed
    var currentKeyPressed: UInt16? = nil
    
    // Determines how quickly the camera moves in response to a key press
    let keyMoveSensitivity: Float = 0.3

    
    // Touchscreen controls
    var movingFingerDisplacement = CGPoint(x: 0.0, y: 0.0)
    
    var touchScaleFactor: Float = 0.03
    
    
    var cameraVelocity = float3(0.0, 0.0, 0.0)
    
    init(fovy: Float,
         aspectRatio: Float,
         nearZ: Float,
         farZ: Float,
         position: float3) {
        
        
        projectionMatrix = Maths.createProjectionMatrix(fovy: fovy,
                                                        aspectRatio: aspectRatio,
                                                        nearZ: nearZ,
                                                        farZ: farZ)
        self.position = position
                
        super.init()
 
    }
    
    func updateState() {
        
        // We won't store the up and forward vectors; rather, we'll leave them as computed
        // vectors
        
        // Calculate the camera vectors:

        let forwardVector = calculateForwardVector()
        let upVector = calculateUpVector()
        let rightVector = simd_normalize(simd_cross(forwardVector, upVector))
        
        // Then form the rotation matrices
        let azimuthRotation = Maths.createAxisRotation(radians: -azimuth, axis: upVector)
        let elevationRotation = Maths.createAxisRotation(radians: elevation, axis: rightVector)
        rotationMatrix = elevationRotation * azimuthRotation
        
        // Here we listen to key inputs ... we advance the camera in the direction
        // of the forward vector
        let translation1 = Maths.createTranslationMatrix(vector: -position)
        let localDisplacement = calculateDisplacement(forwardVector: forwardVector, rightVector: rightVector)
        let translation2 = Maths.createTranslationMatrix(vector: localDisplacement)
        
        position = position + localDisplacement
        currentViewMatrix = rotationMatrix * translation2 * translation1
        
        movingFingerDisplacement = CGPoint(x: 0.0, y: 0.0)
        
    }
    

    func calculateForwardVector() -> float3 {
        
        let forwardXZProj =  cosf(elevation) // Projection onto the X-Z plane
        let forwardXProj  = -forwardXZProj * sinf(azimuth)
        let forwardYProj  = -sinf(elevation)
        let forwardZProj  = -forwardXZProj * cosf(azimuth)
        
        return  simd_normalize(float3(forwardXProj, forwardYProj, forwardZProj))
        
    }
    
    func calculateUpVector() -> float3 {
        
        let upXZProj = -sinf(elevation) // Also a projection onto the X-Z plane
        let upXProj  = upXZProj * sinf(azimuth)
        let upYProj  = cosf(elevation)
        let upZProj  = upXZProj * cosf(azimuth)
        
        return simd_normalize(float3(upXProj, upYProj, upZProj))
        
    }
    
    func calculateDisplacement(forwardVector: float3, rightVector: float3) -> float3 {
        
        if movementInputDevice == .keyboard {
            return calculateVelocityFromKey(forwardVector: forwardVector, rightVector: rightVector)
        } else {
            return calculateVelocityFromTouch(forwardVector: forwardVector, rightVector: rightVector)
        }
        
    }
    
    func calculateVelocityFromKey(forwardVector: float3, rightVector: float3) -> float3 {

        var velocity = float3(0.0, 0.0, 0.0)
        if keyIsPressed {
            if let key = currentKeyPressed {
                switch key {
                case Alphanumerics.VK_ANSI_W.rawValue:
                    velocity =  simd_normalize(float3(forwardVector.x, 0.0, forwardVector.z))
                case Alphanumerics.VK_ANSI_A.rawValue:
                    velocity = -rightVector
                case Alphanumerics.VK_ANSI_S.rawValue:
                    velocity = -simd_normalize(float3(forwardVector.x, 0.0, forwardVector.z))
                case Alphanumerics.VK_ANSI_D.rawValue:
                    velocity =  rightVector
                case Alphanumerics.VK_ANSI_P.rawValue:
                    print("Position: " + position.debugDescription)
                case Alphanumerics.VK_ANSI_Z.rawValue:
                    print("Azmith: \(Maths.radiansToDegrees(radians: azimuth)) degrees")
                case Alphanumerics.VK_ANSI_E.rawValue:
                    print("Elevation: \(Maths.radiansToDegrees(radians: elevation)) degrees")
                default:
                    break
                }
                
                velocity *= keyMoveSensitivity
                
            }

        }

        return velocity
    }

    
    
    func calculateVelocityFromTouch(forwardVector: float3, rightVector: float3) -> float3 {
        
        let forwardVelocity  = Float(movingFingerDisplacement.y) * simd_normalize(float3(forwardVector.x, 0.0, forwardVector.z))
        let sidewaysVelocity = Float(movingFingerDisplacement.x) * rightVector
        
        return  touchScaleFactor * (-forwardVelocity + sidewaysVelocity)
    }
}

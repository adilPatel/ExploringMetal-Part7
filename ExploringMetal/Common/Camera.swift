//
//  Camera.swift
//  ExploringMetal
//
//  Created by Adil Patel on 05/07/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Cocoa
import simd

class Camera: NSObject, UserInteractionDelegate, AnimatedObject {

    
    // Keep this as a 3D vector as we're incrementing
    var position = float3(0.0, 0.0, 0.0)
    
    // Determines how quickly the camera moves in response to a key press
    let moveSensitivity: Float = 0.3
    
    // If a key is pressed already
    var keyIsPressed = false
    
    // The current key which is pressed ... nil if nothing is pressed
    var currentKeyPressed: UInt16? = nil
    
    // The mouse position in screen coordinates
    var mousePosition: CGPoint? = nil
    
    // The azimuth angle of the camera w.r.t. the -z axis
    var azimuth: Float = 0.0
    
    // The elevation angle of the camera w.r.t. the y axis
    var elevation: Float = 0.0
    
    // Determines how quickly the camera rotates in response to a mouse event
    let azimuthSensitivity: Float = -0.01
    
    // Determines how quickly the camera rotates in response to a mouse event
    let elevationSensitivity: Float = -0.01
    
    // Fetched by the scene using it in its update loop
    var currentViewMatrix = matrix_identity_float4x4
    
    // The projection matrix is handled by the camera
    var projectionMatrix: matrix_float4x4
    

    init(fovy: Float,
         aspectRatio: Float,
         nearZ: Float,
         farZ: Float) {
        
        
        projectionMatrix = Maths.createProjectionMatrix(fovy: fovy,
                                                        aspectRatio: aspectRatio,
                                                        nearZ: nearZ,
                                                        farZ: farZ)
        
                
        super.init()
 
    }
    
    func updateState() {
        
        // We won't store the up and forward vectors; rather, we'll leave them as computed
        // vectors
        
        // Calculate the forward vector
        let forwardXZProj =  cosf(elevation) // Projection onto the X-Z plane
        let forwardXProj  = -forwardXZProj * sinf(azimuth)
        let forwardYProj  = -sinf(elevation)
        let forwardZProj  = -forwardXZProj * cosf(azimuth)
        let forwardVector =  simd_normalize(float3(forwardXProj, forwardYProj, forwardZProj))
        
        // Calculate the upwards vector
        let upXZProj = -sinf(elevation) // Also a projection onto the X-Z plane
        let upXProj  = upXZProj * sinf(azimuth)
        let upYProj  = cosf(elevation)
        let upZProj  = upXZProj * cosf(azimuth)
        let upVector = simd_normalize(float3(upXProj, upYProj, upZProj))
        
        // Right-facing vector is derived from the cross product
        let rightVector = simd_normalize(simd_cross(forwardVector, upVector))
        
        // Then form the rotation matrices
        let azimuthRotation = Maths.createAxisRotation(radians: -azimuth, axis: upVector)
        let elevationRotation = Maths.createAxisRotation(radians: elevation, axis: rightVector)
        let rotationMatrix = elevationRotation * azimuthRotation
        
        // Here we listen to key inputs ... we advance the camera in the direction
        // of the forward vector
        let translation1 = Maths.createTranslationMatrix(vector: -position)
        
        var translation2 = matrix_identity_float4x4
                if keyIsPressed {
                    if let key = currentKeyPressed {
        
                        var localDisplacement = float3()
        
                        switch key {
                        case Alphanumerics.VK_ANSI_W.rawValue:
                            localDisplacement = forwardVector
                        case Alphanumerics.VK_ANSI_A.rawValue:
                            localDisplacement = -rightVector
                        case Alphanumerics.VK_ANSI_S.rawValue:
                            localDisplacement = -forwardVector
                        case Alphanumerics.VK_ANSI_D.rawValue:
                            localDisplacement = rightVector
                        case Alphanumerics.VK_ANSI_P.rawValue:
                            print("Position: " + position.debugDescription)
                        case Alphanumerics.VK_ANSI_R.rawValue:
                            print("Right vector: " + rightVector.debugDescription)
                        case Alphanumerics.VK_ANSI_U.rawValue:
                            print("Up vector: " + upVector.debugDescription)
                        case Alphanumerics.VK_ANSI_F.rawValue:
                            print("Forward vector" + forwardVector.debugDescription)
                        case Alphanumerics.VK_ANSI_Z.rawValue:
                            print("Azmith: \(Maths.radiansToDegrees(radians: azimuth)) degrees")
                        case Alphanumerics.VK_ANSI_E.rawValue:
                            print("Elevation: \(Maths.radiansToDegrees(radians: elevation)) degrees")
                        case Alphanumerics.VK_ANSI_O.rawValue:
                            print("Up dot forward: \(simd_dot(upVector, forwardVector))")
                        default:
                            localDisplacement = float3(0.0,  0.0,  0.0)
                        }
                        // No need to normalise after computing the cross product, as they're
                        // orthogonal unit vectors!
        
                        localDisplacement = moveSensitivity * localDisplacement
                        translation2 = Maths.createTranslationMatrix(vector: -localDisplacement)
        
                        // Add it to the camera vector pointing directions
                        position = position + localDisplacement
        
                        // When displacing the camera's position, we do NOT alter the forward vector
                        // nor the upward vector
        
                    }
                }
        
        
        currentViewMatrix = rotationMatrix * translation2 * translation1
        
    }
    
    func keyDown(key: UInt16) {
        
        // Ignore the callback if the key is already pressed
        if !keyIsPressed {
            currentKeyPressed = key
            keyIsPressed = true
        }
        
    }
    
    func keyUp(key: UInt16) {
        keyIsPressed = false
        currentKeyPressed = nil
    }
    
    func mouseMoved(position: CGPoint) {
        if let currentPosition = mousePosition {
            let dx = Float(position.x - currentPosition.x)
            let dy = Float(position.y - currentPosition.y)
            azimuth   += azimuthSensitivity   * dx
            elevation += elevationSensitivity * dy
        }
        mousePosition = position
    }

}

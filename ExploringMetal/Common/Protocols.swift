//
//  Protocols.swift
//  ExploringMetal
//
//  Created by Adil Patel on 05/07/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation

protocol UserInteractionDelegate {
        
    // Methods here are optional because they're device-specific
    func keyDown(key: UInt16)
    func keyUp(key: UInt16)
    func mouseMoved(position: CGPoint)
    
}

extension UserInteractionDelegate {
    
    func keyDown(key: UInt16) {}
    func keyUp(key: UInt16) {}
    func mouseMoved(position: CGPoint) {}
    
}

protocol AnimatedObject {
    
    func updateState() 
    
}


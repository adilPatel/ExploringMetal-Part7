//
//  ConvenienceExtensions.swift
//  ExploringMetal
//
//  Created by Adil Patel on 27/07/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import simd

#if os(OSX)
import Cocoa
#else
import UIKit
#endif

extension CGPoint {
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let x = lhs.x + rhs.x
        let y = lhs.y + rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return CGPoint(x: dx, y: dy)
    }
    
    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }
    
    static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }
    
}

extension float3 {
    
    init(_ fourVector: float4) {
        self.init(fourVector.x, fourVector.y, fourVector.z)
    }
    
    static func += (lhs: inout float3, rhs: float3) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs: inout float3, rhs: float3) {
        lhs = lhs - rhs
    }
    
}

extension float4 {
    
    init(_ threeVector: float3, _ fourth: Float) {
        self.init(threeVector.x, threeVector.y, threeVector.z, fourth)
    }
    
    static func += (lhs: inout float4, rhs: float4) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs: inout float4, rhs: float4) {
        lhs = lhs - rhs
    }
    
}

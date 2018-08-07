//
//  TouchInput.swift
//  ExploringMetal_iOS
//
//  Created by Adil Patel on 26/07/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import UIKit

protocol TouchInputDelegate {
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView)
    
}

extension TouchInputDelegate {
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) {}
    
}

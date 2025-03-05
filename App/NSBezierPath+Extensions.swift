//
//  NSBezierPath+Extensions.swift
//  NSCollectionViewDragDrop
//
//  Created by Harry Ng on 9/3/2016.
//  Copyright © 2016 STAY REAL. All rights reserved.
//

import Cocoa

extension NSBezierPath {
    func toCGPath () -> CGPath? {
        if self.elementCount == 0 {
            return nil
        }
        
        let path = CGMutablePath()
        var didClosePath = false
        
        for i in 0...self.elementCount-1 {
            var points = [NSPoint](repeating: NSZeroPoint, count: 3)
          
            switch self.element(at: i, associatedPoints: &points) {
            case .moveToBezierPathElement: path.move(to: points[0])
            case .lineToBezierPathElement: path.addLine(to: points[0])
            case .curveToBezierPathElement: path.addCurve(to: points[0], control1: points[1], control2: points[2])
            case .closePathBezierPathElement: path.closeSubpath()
            didClosePath = true;
            }
        }
        
        if !didClosePath {
            path.closeSubpath()
        }
        
        return path.copy()
    }
}

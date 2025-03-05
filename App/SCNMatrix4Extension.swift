//
//  SCNMatrix4_Extension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 08.08.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Foundation
import SceneKit

extension SCNMatrix4 {
  
  
}

class SCNMatrix4Coding: NSObject, NSCoding {
  let matrix: SCNMatrix4
  
  init(_ matrix: SCNMatrix4) {
    self.matrix = matrix
  }
  
  required init?(coder aDecoder: NSCoder) {
    self.matrix = SCNMatrix4(m11: CGFloat(aDecoder.decodeDouble(forKey: "m11")), 
                             m12: CGFloat(aDecoder.decodeDouble(forKey: "m12")), 
                             m13: CGFloat(aDecoder.decodeDouble(forKey: "m13")), 
                             m14: CGFloat(aDecoder.decodeDouble(forKey: "m14")), 
                             m21: CGFloat(aDecoder.decodeDouble(forKey: "m21")), 
                             m22: CGFloat(aDecoder.decodeDouble(forKey: "m22")), 
                             m23: CGFloat(aDecoder.decodeDouble(forKey: "m23")), 
                             m24: CGFloat(aDecoder.decodeDouble(forKey: "m24")), 
                             m31: CGFloat(aDecoder.decodeDouble(forKey: "m31")), 
                             m32: CGFloat(aDecoder.decodeDouble(forKey: "m32")), 
                             m33: CGFloat(aDecoder.decodeDouble(forKey: "m33")), 
                             m34: CGFloat(aDecoder.decodeDouble(forKey: "m34")), 
                             m41: CGFloat(aDecoder.decodeDouble(forKey: "m41")), 
                             m42: CGFloat(aDecoder.decodeDouble(forKey: "m42")), 
                             m43: CGFloat(aDecoder.decodeDouble(forKey: "m43")), 
                             m44: CGFloat(aDecoder.decodeDouble(forKey: "m44")))
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(Double(matrix.m11), forKey: "m11")
    aCoder.encode(Double(matrix.m12), forKey: "m12")
    aCoder.encode(Double(matrix.m13), forKey: "m13")
    aCoder.encode(Double(matrix.m14), forKey: "m14")
    aCoder.encode(Double(matrix.m21), forKey: "m21")
    aCoder.encode(Double(matrix.m22), forKey: "m22")
    aCoder.encode(Double(matrix.m23), forKey: "m23")
    aCoder.encode(Double(matrix.m24), forKey: "m24")
    aCoder.encode(Double(matrix.m31), forKey: "m31")
    aCoder.encode(Double(matrix.m32), forKey: "m32")
    aCoder.encode(Double(matrix.m33), forKey: "m33")
    aCoder.encode(Double(matrix.m34), forKey: "m34")
    aCoder.encode(Double(matrix.m41), forKey: "m41")
    aCoder.encode(Double(matrix.m42), forKey: "m42")
    aCoder.encode(Double(matrix.m43), forKey: "m43")
    aCoder.encode(Double(matrix.m44), forKey: "m44")
  }
}

public func *(left: SCNMatrix4, right: SCNVector4) -> SCNVector4 {
  let v: SCNVector4 = SCNVector4Make(
    left.m11*right.x + left.m12*right.y + left.m13*right.z + left.m14*right.w, 
    left.m21*right.x + left.m22*right.y + left.m23*right.z + left.m24*right.w, 
    left.m31*right.x + left.m32*right.y + left.m33*right.z + left.m34*right.w,
    left.m41*right.x + left.m42*right.y + left.m43*right.z + left.m44*right.w
  )
  return v
}

public func *(left: SCNMatrix4, right: SCNMatrix4) -> SCNMatrix4 {
  return SCNMatrix4Mult(left, right)
}

//
//  SCNVector4Extension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 08.08.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector4 {
  init (_ v: SCNVector3, _ w: CGFloat) {
    self.init(v.x, v.y, v.z, w)
  }
  
  init (_ v: GLKVector3, _ w: CGFloat) {
    self.init(CGFloat(v.x), CGFloat(v.y), CGFloat(v.z), w)
  }
  
}

class SCNVector4Coding: NSObject, NSCoding {
  let vector: SCNVector4
  
  init(_ vector: SCNVector4) {
    self.vector = vector
  }
  
  required init?(coder aDecoder: NSCoder) {
    self.vector = SCNVector4(x: CGFloat(aDecoder.decodeDouble(forKey: "x")), 
                             y: CGFloat(aDecoder.decodeDouble(forKey: "y")), 
                             z: CGFloat(aDecoder.decodeDouble(forKey: "z")),
                             w: CGFloat(aDecoder.decodeDouble(forKey: "w")))
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(Double(vector.x), forKey: "x")
    aCoder.encode(Double(vector.y), forKey: "y")
    aCoder.encode(Double(vector.z), forKey: "z")
    aCoder.encode(Double(vector.w), forKey: "w")
  }
}

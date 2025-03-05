//
//  SHPerspectiveData.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 28.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit
import SceneKit

fileprivate let name_key = "name_key"
fileprivate let shortcut_key = "shortcut_key"
fileprivate let image_key = "image_key"
fileprivate let cam_orbit_transform_key = "cam_orbit_transform_key"
fileprivate let cam_orbit_angles_key = "cam_orbit_angles_key"
fileprivate let cam_position_key = "cam_position_key"
fileprivate let zoom_factor_key = "zoom_factor_key"
fileprivate let plane_orbit_transform_key = "plane_orbit_transform_key"
fileprivate let plane_orbit_angles_key = "plane_orbit_angles_key"
fileprivate let plane_position_key = "plane_position_key"

class SHPerspectiveData: NSObject, NSCoding {
  var name: String?
  var shortcut: String?
  var image: NSImage?
  
  var camOrbitTransform: SCNMatrix4?
  var camOrbitAngles: SCNVector3?
  var camPosition: SCNVector3?
  var zoomFactor: CGFloat?
  var planeOrbitTransform: SCNMatrix4?
  var planeOrbitAngles: SCNVector3?
  var planePosition: SCNVector3?
  
  override init() {
    super.init()
  }
  
  // MARK: NSCoding functions
  
  required init(coder aDecoder: NSCoder) {
    super.init()
    if let name = aDecoder.decodeObject(forKey: name_key) as? String {
      self.name = name
    }
    if let shortcut = aDecoder.decodeObject(forKey: shortcut_key) as? String {
      self.shortcut = shortcut
    }
    if let image = aDecoder.decodeObject(forKey: image_key) as? NSImage {
      self.image = image
    }
    
    if let camOrbitTransform = aDecoder.decodeObject(forKey: cam_orbit_transform_key) as? SCNMatrix4Coding {
      self.camOrbitTransform = camOrbitTransform.matrix
    }
    if let camOrbitAngles = aDecoder.decodeObject(forKey: cam_orbit_angles_key) as? SCNVector3Coding {
      self.camOrbitAngles = camOrbitAngles.vector
    }
    if let camPosition = aDecoder.decodeObject(forKey: cam_position_key) as? SCNVector3Coding {
      self.camPosition = camPosition.vector
    }
    if aDecoder.containsValue(forKey: zoom_factor_key) {
      self.zoomFactor = CGFloat(aDecoder.decodeDouble(forKey: zoom_factor_key))
    }
    if let planeOrbitTransform = aDecoder.decodeObject(forKey: plane_orbit_transform_key) as? SCNMatrix4Coding {
      self.planeOrbitTransform = planeOrbitTransform.matrix
    }
    if let planeOrbitAngles = aDecoder.decodeObject(forKey: plane_orbit_angles_key) as? SCNVector3Coding {
      self.planeOrbitAngles = planeOrbitAngles.vector
    }
    if let planePosition = aDecoder.decodeObject(forKey: plane_position_key) as? SCNVector3Coding {
      self.planePosition = planePosition.vector
    }
  }
  
  
  func encode(with aCoder: NSCoder) {
    if let name = self.name {
      aCoder.encode(name, forKey: name_key)
    }
    if let shortcut = self.shortcut {
      aCoder.encode(shortcut, forKey: shortcut_key)
    }
    if let image = self.image {
      aCoder.encode(image, forKey: image_key)
    }
    if let camOrbitTransform = self.camOrbitTransform {
      aCoder.encode(SCNMatrix4Coding(camOrbitTransform), forKey: cam_orbit_transform_key)
    }
    if let camOrbitAngles = self.camOrbitAngles {
      aCoder.encode(SCNVector3Coding(camOrbitAngles), forKey: cam_orbit_angles_key)
    }
    if let camPosition = self.camPosition {
      aCoder.encode(SCNVector3Coding(camPosition), forKey: cam_position_key)
    }
    if let zoomFactor = self.zoomFactor {
      aCoder.encode(Double(zoomFactor), forKey: zoom_factor_key)
    }
    if let planeOrbitTransform = self.planeOrbitTransform {
      aCoder.encode(SCNMatrix4Coding(planeOrbitTransform), forKey: plane_orbit_transform_key)
    }
    if let planeOrbitAngles = self.planeOrbitAngles {
      aCoder.encode(SCNVector3Coding(planeOrbitAngles), forKey: plane_orbit_angles_key)
    }
    if let planePosition = self.planePosition {
      aCoder.encode(SCNVector3Coding(planePosition), forKey: plane_position_key)
    }
  }
  
}

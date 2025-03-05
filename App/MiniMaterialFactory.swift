//
//  MiniMaterialFactory.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 27.01.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Foundation
import SceneKit

class MiniMaterialFactory: MaterialFactory {
  
  override func initNodeTree(_ node: SCNNode) {
    if let geo = node.geometry {
      for material in geo.materials {
        material.isDoubleSided = false
        createLight(forMaterial: material)
        createFrontMaterials(for: material)
      }
    }
    
    for child in node.childNodes {
      self.initNodeTree(child)
    }
  }
  
  func createFrontMaterials(for m: SCNMaterial) {
    if let materialName = m.name {
      if let materialSettings = settingsPList[materialName] as? [String: AnyObject] {
        if let programName = materialSettings["program"] as? String {
          m.program = programMap[programName]
        } else {
          let alert = NSAlert()
          alert.messageText = "No program found for material \(materialName)."
          alert.runModal()
        }
        if let frontSettings = materialSettings["front"] as? [String: AnyObject] {
          createOpenGLMaterial(m, prefix: "front", settings: frontSettings)
        } else {
          let alert = NSAlert()
          alert.messageText = "No front settings found for material \(materialName)."
          alert.runModal()
        }
      } else {
        let alert = NSAlert()
        alert.messageText = "Material \(materialName) not found in settings."
        alert.runModal()
      }
    }
  }
  
}

//
//  MaterialFactory.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 01.09.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import SceneKit

private var KVOContext: Int = 0

class SHMaterial: NSObject {
  var r0: Float
  var specExp: Float
  var clipFlag: Bool
  var textureFlag: Bool
  var color: vector_float3
  @objc dynamic var userDefaultColor: NSColor? {
    didSet {
      if let usr = userDefaultColor {
        if let rgbColor = usr.usingColorSpaceName(NSColorSpaceName.calibratedRGB) {
          color = vector_float3(Float(rgbColor.redComponent), Float(rgbColor.greenComponent), Float(rgbColor.blueComponent))
        }
      }
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    
    guard context == &KVOContext else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    
    if let object = change?[NSKeyValueChangeKey.newKey] {
      if let data = object as? Data {      
        if let color = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSColor {
          self.userDefaultColor = color
        }
      }
    }
  }
  
  init(r0: Float, specExp: Float, clip: Bool, texture: Bool, color: vector_float3) {
    self.r0 = r0
    self.specExp = specExp
    self.clipFlag = clip
    self.textureFlag = texture
    self.color = color
  }
}

class MaterialFactory: NSObject {
  
  weak var userDefaultsController: NSUserDefaultsController?
  
  var delegate: MaterialFactoryDelegate?
  
  var openGLContext: NSOpenGLContext?
  let settingsPList: [String: AnyObject]
  var textureMap = [String: AnyObject]()
  var materialList = [SHMaterial]()
  
  let programMap: [String: SCNProgram]
    
  let textureFileType: String = "jpg"
  
  var texturesToLoad: Int = 0
  var texturesLoaded: Int = 0 {
    didSet {
      if texturesLoaded == texturesToLoad {
        self.delegate?.didLoadTextures()
      }
    }
  }
  
  var clipPlaneNormal: SCNVector3 = SCNVector3Make(0.0, 0.0, 1.0)
  var clipPlaneDistance: CGFloat = 0.0
  
  var lightPosition: SCNVector3 = SCNVector3Make(0.2, 0.2, 0.0)
  
  var directColor = vector_float3(1.0, 1.0, 1.0)
  var ambientColor = vector_float3(1.5, 1.5, 1.5)
  
  @objc dynamic var lightSlider: NSNumber = NSNumber(value: 1.0)
  
  init(withOpenGLContext context: NSOpenGLContext, settings: [String: AnyObject], programs: [String: SCNProgram]) {
    openGLContext = context
    settingsPList = settings
    programMap = programs
  }
  
  func initNodeTree(_ node: SCNNode) {
    if let geo = node.geometry {
      for material in geo.materials {
        material.isDoubleSided = true
        material.isLitPerPixel = true
        createClipPlane(forMaterial: material)
        createLight(forMaterial: material)
        createFrontBackMaterials(forMaterial: material)
      }
    }
    
    for child in node.childNodes {
      self.initNodeTree(child)
    }
  }
  
  func changeProgram(_ node: SCNNode, programName name: String) {
    if let geo = node.geometry {
      for material in geo.materials {
        if let _ = material.name {
          material.program = self.programMap[name]
        }
      }
    }
    
    for child in node.childNodes {
      self.changeProgram(child, programName: name)
    }
  }
  
  func createClipPlane(forMaterial m: SCNMaterial) {
    m.handleBinding(ofSymbol: "clip_plane", handler: {(programID, location, node, renderer) -> Void in
      glEnable(GLenum(GL_CLIP_DISTANCE0))
      glUniform4f(GLint(location), 
                  GLfloat(self.clipPlaneNormal.x), 
                  GLfloat(self.clipPlaneNormal.y), 
                  GLfloat(self.clipPlaneNormal.z), 
                  GLfloat(self.clipPlaneDistance))
    })
  }
    
  func createLight(forMaterial m: SCNMaterial) {
    m.handleBinding(ofSymbol: "light_position", handler: {(programID, location, node, renderer) -> Void in
      glUniform3f(GLint(location), GLfloat(self.lightPosition.x), GLfloat(self.lightPosition.y), GLfloat(self.lightPosition.z))
    })
    
    m.handleBinding(ofSymbol: "direct_color", handler: {(programID, location, node, renderer) -> Void in
      glUniform3f(
        GLint(location),
        self.directColor.x+self.lightSlider.floatValue/2,
        self.directColor.y+self.lightSlider.floatValue/2,
        self.directColor.z+self.lightSlider.floatValue/2
      )
    })
    
    m.handleBinding(ofSymbol: "ambient_color", handler: {(programID, location, node, renderer) -> Void in
      glUniform3f(
        GLint(location),
        self.ambientColor.x-self.lightSlider.floatValue,
        self.ambientColor.y-self.lightSlider.floatValue,
        self.ambientColor.z-self.lightSlider.floatValue
      )
    })
  }
  
  func createFrontBackMaterials(forMaterial m: SCNMaterial) {
    if let materialName = m.name, materialName != "" {
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
        if let backSettings = materialSettings["back"] as? [String: AnyObject] {
          createOpenGLMaterial(m, prefix: "back", settings: backSettings)
        } else {
          let alert = NSAlert()
          alert.messageText = "No back settings found for material \(materialName)."
          alert.runModal()
        }
      } else {
        let alert = NSAlert()
        alert.messageText = "Material \(materialName) not found in settings."
        alert.runModal()
      }
    }
  }
  
  func createOpenGLMaterial(_ material: SCNMaterial, prefix: String, settings: [String: AnyObject]) {
    var textureFlag = false
    if let textureName = settings["texture"] as? String {
      textureFlag = true
      if textureMap[textureName] == nil {
        textureMap[textureName] = textureName as AnyObject?
        if let texturePath = Bundle.main.path(forResource: textureName, ofType: self.textureFileType) {
          self.texturesToLoad += 1
          GLKTextureLoader(share: openGLContext!).texture(withContentsOfFile: texturePath, options: nil, queue: DispatchQueue.main, completionHandler: {
            (tex, error) -> Void in
            if tex != nil {
              self.textureMap[textureName] = tex
              self.texturesLoaded += 1
            } else if let error = error {
              let alert = NSAlert()
              alert.messageText = "Unable to load texture \(textureName)."
              alert.informativeText = error.localizedDescription
              alert.runModal()
            }
          })
        } else {
          let alert = NSAlert()
          alert.messageText = "Resource for texture '\(textureName)' not found."
          alert.runModal()
        }
      }
      
      material.handleBinding(ofSymbol: "diffuseTexture", handler: {(programID, location, node, renderer) -> Void in
        if let texture = self.textureMap[textureName] as? GLKTextureInfo {
          glBindTexture(GLenum(GL_TEXTURE_2D.hashValue), texture.name)
        }
      })
    }
    
    // material color
    var colorVector = vector_float3(0.0, 0.0, 0.0)
    if let color = settings["color"] as? [Float] {
      colorVector = vector_float3(color[0], color[1], color[2])
    }
    
    // material properties
    let r0: Float? = settings["R0"] as? Float
    let specExp: Float? = settings["spec_exp"] as? Float
    
    // shading flags
    let clipShading: Bool = settings["clip_shading"] as! Bool
    
    // create object
    let materialObject = SHMaterial(r0: r0 ?? 0.0, specExp: specExp ?? 1.0,
                                    clip: clipShading, texture: textureFlag,
                                    color: colorVector)
    
    if let userDefaultsColorKey = settings["userDefaultsColorKey"] as? String {
      let defaultsController = NSUserDefaultsController.shared
      materialObject.bind(NSBindingName(rawValue: "userDefaultColor"),
                          to: defaultsController, withKeyPath: "values."+userDefaultsColorKey,
                          options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
      
    }
    
    materialList.append(materialObject)
    
    material.handleBinding(ofSymbol: prefix+"Color", handler: {(programID, location, node, renderer) -> Void in
      glUniform3f(GLint(location), materialObject.color.x, materialObject.color.y, materialObject.color.z)
    })

    material.handleBinding(ofSymbol: prefix+"Props", handler: {(programID, location, node, renderer) -> Void in
      glUniform2f(GLint(location), materialObject.r0, materialObject.specExp)
    })
    
    material.handleBinding(ofSymbol: prefix+"Flags", handler: {(programID, location, node, renderer) -> Void in
      glUniform2f(GLint(location), materialObject.clipFlag ? 1.0 : 0.0, materialObject.textureFlag ? 1.0 : 0.0)
    })
  }
}

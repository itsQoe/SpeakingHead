//
//  SceneFactory.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 01.09.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import SceneKit

fileprivate let scene_key = "scene_key"
fileprivate let mini_scene_key = "mini_scene_key"
fileprivate let morph_target_list_key = "morph_target_list_key"
fileprivate let morph_target_map_key = "morph_target_map_key"
fileprivate let head_key = "head_key"
fileprivate let camera_key = "camera_key"
fileprivate let light_key = "light_key"
fileprivate let cam_orbit_key = "cam_orbit_key"
fileprivate let plane_key = "plane_key"
fileprivate let plane_orbit_key = "plane_orbit_key"
fileprivate let brian_orbit_key = "brian_orbit_key"
fileprivate let mini_head_key = "mini_head_key"
fileprivate let mini_camera_key = "mini_camera_key"
fileprivate let slice_indicator_key = "slice_indicator_key"
fileprivate let slice_handle_key = "slice_handle_key"
fileprivate let slice_material_key = "slice_material_key"

enum ModelQuality: Int {
  case low=0, medium, high
}

class SceneFactory: NSObject, NSCoding {
  let scene: SCNScene
  let miniScene: SCNScene
  
  var morphTargetList: [String]?
  var morphTargetMap: [String: String]?
  
  var head: SCNNode?
  var camera: SCNNode?
  var light: SCNNode?
  var camOrbit: SCNNode?
  var plane: SCNNode?
  var planeOrbit: SCNNode?
  var brian: SCNNode?
  
  var miniHead: SCNNode?
  var miniCamera: SCNNode?
  var sliceIndicator: SCNNode?
  var sliceHandle: SCNNode?
  var sliceMaterial: SCNMaterial?
  @objc dynamic var sliceIndicatorColor: NSColor? {
    didSet {
      sliceMaterial?.emission.contents = sliceIndicatorColor
    }
  }
  
  convenience init(withDAEFile headFile: String, miniDEA miniFile: String) {
    self.init(headScene: SCNScene(named: headFile)!, miniScene: SCNScene(named: headFile)!) 
  }
  
  init(headScene: SCNScene, miniScene: SCNScene) {
    self.scene = headScene
    self.miniScene = miniScene
    super.init()
    self.head = scene.rootNode.childNode(withName: "Head", recursively: false)
    self.brian = head?.childNode(withName: "Brian", recursively: false)
    self.brian?.isHidden = true
    createLighting()
    createClipPlane()
    createMiniScene()
  }
  
  required init?(coder: NSCoder) {
    self.scene = coder.decodeObject(forKey: scene_key) as! SCNScene
    self.miniScene = coder.decodeObject(forKey: mini_scene_key) as! SCNScene
    
    super.init()
    
    self.morphTargetList = coder.decodeObject(forKey: morph_target_list_key) as? [String]
    self.morphTargetMap = coder.decodeObject(forKey: morph_target_map_key) as? [String: String]
    self.head = coder.decodeObject(forKey: head_key) as? SCNNode
    self.camera = coder.decodeObject(forKey: camera_key) as? SCNNode
    self.light = coder.decodeObject(forKey: light_key) as? SCNNode
    self.camOrbit = coder.decodeObject(forKey: cam_orbit_key) as? SCNNode
    self.plane = coder.decodeObject(forKey: plane_key) as? SCNNode
    self.planeOrbit = coder.decodeObject(forKey: plane_orbit_key) as? SCNNode
    self.brian = coder.decodeObject(forKey: brian_orbit_key) as? SCNNode
    self.miniHead = coder.decodeObject(forKey: mini_head_key) as? SCNNode
    self.miniCamera = coder.decodeObject(forKey: mini_camera_key) as? SCNNode
    self.sliceIndicator = coder.decodeObject(forKey: slice_indicator_key) as? SCNNode
    self.sliceHandle = coder.decodeObject(forKey: slice_handle_key) as? SCNNode
    self.sliceMaterial = coder.decodeObject(forKey: slice_material_key) as? SCNMaterial
  }
  
  func encode(with coder: NSCoder) {
    coder.encode(self.scene, forKey: scene_key)
    coder.encode(self.miniScene, forKey: mini_scene_key)
    
    coder.encode(self.morphTargetList, forKey: morph_target_list_key)
    coder.encode(self.morphTargetMap, forKey: morph_target_map_key)
    
    coder.encode(self.head, forKey: head_key)
    coder.encode(self.camera, forKey: camera_key)
    coder.encode(self.light, forKey: light_key)
    coder.encode(self.camOrbit, forKey: cam_orbit_key)
    coder.encode(self.plane, forKey: plane_key)
    coder.encode(self.planeOrbit, forKey: plane_orbit_key)
    coder.encode(self.brian, forKey: brian_orbit_key)
    coder.encode(self.miniHead, forKey: mini_head_key)
    coder.encode(self.miniCamera, forKey: mini_camera_key)
    coder.encode(self.sliceIndicator, forKey: slice_indicator_key)
    coder.encode(self.sliceHandle, forKey: slice_handle_key)
    coder.encode(self.sliceMaterial, forKey: slice_material_key)
  }
  
  func createMorphTargets(_ morphTargetPList: [String: AnyObject]) {
    var myList = [String]()
    var myMap = [String: String]()
    
    func getGeometry(_ fileName: String, nodeName: String) -> SCNGeometry? {
      return SCNScene(named: fileName)?.rootNode.childNode(withName: nodeName, recursively: false)?.geometry
    }
    
    if head != nil {
      var headTargetArray = [SCNGeometry]()
      var targetCount: Int = 0
      
      let headTargetDict: [String: String] = morphTargetPList["Head"] as! [String: String]
      for targetKV in headTargetDict {
        if let geo = getGeometry(targetKV.1, nodeName: "Head") {
          headTargetArray.append(geo)
          myMap[targetKV.0] = NSString(format: "morpher.weights[%i]", targetCount) as String
          myList.append(targetKV.0)
          targetCount += 1
        } else {
          let alert = NSAlert()
          alert.messageText = "Could not import geometry for \(targetKV.1)."
          alert.runModal()
        }
      }
      
      self.head!.morpher = SCNMorpher()
      self.head!.morpher!.targets = headTargetArray
      
      morphTargetList = myList
      morphTargetMap = myMap
    }
  }
    
  func createLighting() {
    // camera
    let cameraOrbit = SCNNode()
    scene.rootNode.addChildNode(cameraOrbit)
    self.camOrbit = cameraOrbit
    
    if let camera: SCNNode = scene.rootNode.childNode(withName: "Camera", recursively: true) {
      camera.removeFromParentNode()
      cameraOrbit.addChildNode(camera)
      self.camera = camera
    } else {
      let camNode = SCNNode()
      camNode.name = "Camera"
      camNode.camera = SCNCamera()
      camNode.camera!.fieldOfView = 45.0
      camNode.camera!.usesOrthographicProjection = true
      // camNode.position.z = headView!.cameraMaxZ
      cameraOrbit.addChildNode(camNode)
      self.camera = camNode
    }
    
    // light
    if let lamp = scene.rootNode.childNode(withName: "Lamp", recursively: true) {
      lamp.removeFromParentNode()
      cameraOrbit.addChildNode(lamp)
    } else {
      let lightNode = SCNNode()
      lightNode.light = SCNLight()
      // lightNode.position.z = headView!.cameraMaxZ
      cameraOrbit.addChildNode(lightNode)
      self.light = lightNode
    }
  }
  
  func createClipPlane() {
    self.plane = SCNNode()
    self.plane?.name = "Plane"
    self.plane?.geometry = SCNPlane(width: 3.0, height: 2.0)
    self.plane?.geometry?.firstMaterial?.diffuse.contents = NSColor.green
    self.plane?.geometry?.firstMaterial?.isDoubleSided = true
    self.plane?.isHidden = true
    let planeOrbit = SCNNode()
    planeOrbit.addChildNode(self.plane!)
    self.planeOrbit = planeOrbit
    self.head?.addChildNode(planeOrbit)
  }
  
  func createMiniScene() {
    // transparent background
    self.miniScene.background.contents = NSColor.clear
    // Mini Head
    self.miniHead = miniScene.rootNode.childNode(withName: "Head", recursively: false)!
    
    guard miniHead != nil else {
      return
    }
    
    miniHead!.position = SCNVector3Make(0.0, 0.0, 0.0)
    miniHead!.geometry!.firstMaterial!.lightingModel = SCNMaterial.LightingModel.blinn
    
    //      let miniProgram = SCNProgram()
    //      miniProgram.delegate = self
    //      miniProgram.vertexFunctionName = "mini_vertex_func"
    //      miniProgram.fragmentFunctionName = "mini_fragment_func"
    //      let miniMaterial = miniHead.geometry!.materialWithName("Skin")
    //      miniMaterial!.program = miniProgram
    //      var miniGPUMaterial: GPUMaterial = GPUMaterial(color: vector_float3(1.0, 0.7, 0.5), prop: vector_float3(0.028, 1000.0, 0.0))
    //      miniMaterial!.setValue(NSData(bytes: &miniGPUMaterial, length: sizeof(GPUMaterial)), forKey: "material")
    
    // slice material
    self.sliceMaterial = SCNMaterial()
    sliceMaterial?.diffuse.contents = NSColor.black
    sliceMaterial?.specular.contents = NSColor.black
    sliceMaterial?.emission.contents = NSColor.red
    sliceMaterial?.lightingModel = SCNMaterial.LightingModel.constant
    
    // get bounding box
    let boundingBox = miniHead!.boundingBox
    let sliceGeo = SCNPlane(width: 0.03, height: boundingBox.max.y - boundingBox.min.y)
    sliceGeo.materials = [sliceMaterial!]
    let sliceIndicator = SCNNode(geometry: sliceGeo)
    
    miniScene.rootNode.addChildNode(sliceIndicator)
    self.sliceIndicator = sliceIndicator
      
    // handles
    let trianglePath = NSBezierPath()
    trianglePath.move(to: NSPoint(x: -0.1, y: 0.0))
    trianglePath.line(to: NSPoint(x: 0.1, y: 0.0))
    trianglePath.line(to: NSPoint(x: 0.0, y: 0.2))
    trianglePath.close()
    
    let handleGeo = SCNShape(path: trianglePath, extrusionDepth: 0.0)
    handleGeo.materials = [sliceMaterial!]
    let sliceHandle = SCNNode(geometry: handleGeo)
    sliceHandle.position.y = -1.0
    sliceIndicator.addChildNode(sliceHandle)
    self.sliceHandle = sliceHandle
    
    // init camera
    let camNode = SCNNode()
    camNode.name = "Camera"
    camNode.camera = SCNCamera()
    camNode.camera!.fieldOfView = 45.0
    camNode.camera!.usesOrthographicProjection = true
    camNode.position = SCNVector3Make(0.0, 0.3, 6.0)
    miniScene.rootNode.addChildNode(camNode)
    self.miniCamera = camNode
    
    // init lighting
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.position.z = 4.0
    miniScene.rootNode.addChildNode(lightNode)
  }
}

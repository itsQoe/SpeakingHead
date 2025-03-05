//
//  HeadView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 07.09.15.
//  Copyright (c) 2015 Uli Held. All rights reserved.
//

import SceneKit

var HeadViewKVOContext: Int = 0

@objc(HeadView) class HeadView: SCNView, SCNSceneRendererDelegate {
  var api: SCNRenderingAPI?
  
  var animController: AnimationController?
  
  var sceneFactory: SceneFactory?
  var materialFactory: MaterialFactory?
  var imageRenderer: SCNRenderer?
  
  @objc dynamic var lightSlider: NSNumber = 0.5 {
    didSet {
      self.backgroundColor = NSColor(calibratedWhite: CGFloat(1.0 - lightSlider.floatValue), alpha: 1.0)
    }
  }
  
  let camera_x_range: ClosedRange<CGFloat> = -2.0 ... 2.0
  let camera_y_range: ClosedRange<CGFloat> = -2.0 ... 2.0
  
  let maxBound: CGFloat = 1.5
  let max_zoom: CGFloat = 1.7
  let min_zoom: CGFloat = 0.5
  var zoom_factor: CGFloat = 1.0 {
    didSet {
      sceneFactory?.head?.scale = SCNVector3(zoom_factor, zoom_factor, zoom_factor)
    }
  }
  
  @objc dynamic var brianIsVisible: Bool = false {
    didSet {
      sceneFactory?.brian?.isHidden = !brianIsVisible
    }
  }
  
  var mini_zoom_factor: CGFloat = 0.7
  let miniZoomTransform = SCNMatrix4MakeScale(0.7, 0.7, 0.7)
  
  var zoomSwitch: Bool = false
  var cameraMaxZ: CGFloat = 4
  var cameraMinZ: CGFloat = 2
  var zoomPosZ: CGFloat = 0.9
  var zoomPosY: CGFloat = -0.6
  
  var cameraX: CGFloat = 0.0
  var cameraY: CGFloat = 0.0
  var miniCameraX: CGFloat = 0.0
  var miniCameraY: CGFloat = 0.0
  var planeRadius: CGFloat = 0.0
  
  var repeatFlag: Bool = false
  var animFactory: AnimationFactory?
  
  var shiftState: Bool = false
  
  var miniCamNode: SCNNode = SCNNode()
  let leftTransform = SCNMatrix4MakeRotation(-CGFloat.pi/2.0, 0.0, 1.0, 0.0)
  let rightTransform = SCNMatrix4MakeRotation(CGFloat.pi/2.0, 0.0, 1.0, 0.0)
  
  var perspective: SHPerspectiveData {
    get {
      let newPerspective = SHPerspectiveData()
      newPerspective.camPosition = sceneFactory?.camera?.position
      newPerspective.camOrbitTransform = sceneFactory?.camOrbit?.transform
      newPerspective.camOrbitAngles = sceneFactory?.camOrbit?.eulerAngles
      newPerspective.zoomFactor = zoom_factor
      newPerspective.planePosition = sceneFactory?.plane?.position
      newPerspective.planeOrbitTransform = miniCamNode.transform
      newPerspective.planeOrbitAngles = miniCamNode.eulerAngles
      return newPerspective
    }
    set(perspective) {
      if let position = perspective.camPosition {
        sceneFactory?.camera?.position = position
      }
      if let angles = perspective.camOrbitAngles {
        sceneFactory?.camOrbit?.eulerAngles = angles
      }
      if let zoom = perspective.zoomFactor {
        self.zoom_factor = zoom
      }
      if let position = perspective.planePosition {
        sceneFactory?.plane?.position = position
      }
      if let angles = perspective.planeOrbitAngles {
        miniCamNode.eulerAngles = angles
        sceneFactory?.planeOrbit?.transform = leftTransform * miniCamNode.transform * rightTransform
      }
      saveToDefaults()
    }
  }
  
  override init(frame: NSRect, options: [String : Any]?) {
    if let api = options![SCNView.Option.preferredRenderingAPI.rawValue] as? SCNRenderingAPI {
      self.api = api
    }

    super.init(frame: frame, options: options)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func initScene() {
    self.backgroundColor = NSColor(calibratedWhite: CGFloat(1.0 - lightSlider.floatValue), alpha: 1.0)
    
    let openGLContext = NSOpenGLContext(format: self.openGLContext!.pixelFormat, share: self.openGLContext)
    imageRenderer = SCNRenderer(context: openGLContext!.cglContextObj, options: nil)
    imageRenderer?.scene = self.scene
    zoom_factor = min_zoom
    
    sceneFactory!.head!.position = SCNVector3Make(0.0, -0.2, 0.0) 
      
    sceneFactory!.planeOrbit!.addObserver(self, forKeyPath: "eulerAngles", options: NSKeyValueObservingOptions(), context: &HeadViewKVOContext)
    sceneFactory!.plane!.addObserver(self, forKeyPath: "position", options: NSKeyValueObservingOptions(), context: &HeadViewKVOContext)
    
    sceneFactory!.plane!.position.z = 1.0
    miniCamNode.eulerAngles.y = CGFloat.pi / 2
    sceneFactory!.planeOrbit!.transform = leftTransform * miniCamNode.transform * rightTransform
    
    sceneFactory!.sliceIndicator!.position.z = 1.5
    sceneFactory!.camera!.position.z = cameraMaxZ
    sceneFactory!.light!.position = SCNVector3Make(-0.5, 0.0, 2.0)
    
    sceneFactory!.miniHead!.scale = SCNVector3Make(mini_zoom_factor, mini_zoom_factor, mini_zoom_factor)

    let defaults = UserDefaults.standard
    if let data = defaults.data(forKey: current_perspective_key) {
      if let defaultPerspective = NSKeyedUnarchiver.unarchiveObject(with: data) as? SHPerspectiveData {
        self.perspective = defaultPerspective
      }
    }    
  }
  
  //MARK: First Responder
  override var acceptsFirstResponder: Bool {
    return true 
  }
  
  override func becomeFirstResponder() -> Bool {
    animController?.closeAllPopovers()
    return true
  }
  
  override func resignFirstResponder() -> Bool {
    return true
  }
  
  override func flagsChanged(with event: NSEvent) {
    self.shiftState = event.modifierFlags.contains(NSEvent.ModifierFlags.shift)
  }
  
  override func scrollWheel(with event: NSEvent) {
    if shiftState {
      var new_plane = sceneFactory!.plane!.position.z - (event.deltaX+event.deltaY)/100 
      
      if new_plane < -maxBound {new_plane = -maxBound}
      if new_plane > maxBound {new_plane = maxBound}
      sceneFactory!.plane!.position = SCNVector3Make(0.0, 0.0, new_plane)
    } else {
      var new_zoom = zoom_factor + (event.deltaX+event.deltaY)/100
      if new_zoom > max_zoom {
        new_zoom = max_zoom
      } else if new_zoom < min_zoom {
        new_zoom = min_zoom
      }
      
      if zoom_factor != new_zoom {
        let oldX = sceneFactory!.camera!.position.x
        let oldY = sceneFactory!.camera!.position.y
        var new_cam_x = oldX
        var new_cam_y = oldY
        
        if zoom_factor < new_zoom && zoom_factor < min_zoom + 0.9 * (max_zoom - min_zoom) {
          let zoomFraction = (new_zoom - zoom_factor) / (max_zoom - zoom_factor)
          
          let p = self.convert(event.locationInWindow, from: nil)
          let worldP = self.unprojectPoint(SCNVector3Make(p.x, p.y, 0.0))
          let camP = sceneFactory!.camOrbit!.convertPosition(worldP, from: nil)
          new_cam_x = oldX + (camP.x - oldX) * zoomFraction
          new_cam_y = oldY + (camP.y - oldY) * zoomFraction
          
        } else if zoom_factor > new_zoom && zoom_factor > min_zoom + 0.1 * (max_zoom - min_zoom) {
          let zoomFraction = (zoom_factor - new_zoom) / (zoom_factor - min_zoom)
          
          new_cam_x = oldX - oldX * zoomFraction
          new_cam_y = oldY - oldY * zoomFraction
        }
        
        zoom_factor = new_zoom
        sceneFactory!.camera!.position = SCNVector3Make(new_cam_x, new_cam_y, cameraMaxZ)
      }
    }
  }
  
  override func mouseUp(with event: NSEvent) {
    saveToDefaults()
  }
  
  override func mouseDragged(with event: NSEvent) {
    if shiftState {
      let new_y = miniCamNode.eulerAngles.y - event.deltaX/self.frame.width*2
      let new_z = miniCamNode.eulerAngles.z - event.deltaY/self.frame.width*2
      miniCamNode.eulerAngles = SCNVector3Make(0.0, new_y, new_z)
      sceneFactory!.planeOrbit!.transform = leftTransform * miniCamNode.transform * rightTransform       
    } else {
      let new_y = sceneFactory!.camOrbit!.eulerAngles.y - event.deltaX/self.frame.width*2
      let new_x = sceneFactory!.camOrbit!.eulerAngles.x - event.deltaY/self.frame.height*2
      sceneFactory!.camOrbit!.eulerAngles = SCNVector3Make(new_x, new_y, 0.0)
    }
  }
  
  override func rightMouseDragged(with event: NSEvent) {
    let new_x: CGFloat = sceneFactory!.camera!.position.x - event.deltaX / self.frame.size.width * 2
    let new_y: CGFloat = sceneFactory!.camera!.position.y + event.deltaY / self.frame.size.height * 2    
    sceneFactory!.camera!.position = SCNVector3Make(camera_x_range.clamp(new_x), camera_y_range.clamp(new_y), cameraMaxZ)
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard context == &HeadViewKVOContext else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    
    // updateClipPlane()
    if let node = object as? SCNNode {
      if node === sceneFactory!.plane || node === sceneFactory!.planeOrbit {
        // rotate mini head
        let viewTransform = sceneFactory!.planeOrbit!.convertTransform(SCNMatrix4Identity, from: sceneFactory!.head!)
        sceneFactory!.miniHead!.transform = miniZoomTransform * viewTransform * rightTransform
        
        // calculate slice indicator position
        let indicatorPos = mini_zoom_factor * 
          SCNVector3Length(sceneFactory!.head!.convertPosition(
            sceneFactory!.plane!.position, from: sceneFactory!.planeOrbit
          ))
        sceneFactory!.sliceIndicator!.position.x = indicatorPos * (sceneFactory!.plane!.position.z > 0.0 ? 1 : -1)
      } 
    } else {    
      self.needsDisplay = true
    }    
  }
      
  func renderImage(withSize imageSize: CGSize) -> CGImage? {
    return imageRenderer!.renderToImageSize(size: imageSize, floatComponents: false, atTime: self.sceneTime)
  }
  
  func perspectiveWithImage() -> SHPerspectiveData {
    let newPerspective = self.perspective
    let imageSize = CGSize(width: 200.0, height: 200.0)
    if let cgImage = renderImage(withSize: imageSize) {
      newPerspective.image = NSImage(cgImage: cgImage, size: imageSize)
    }
    return newPerspective
  }
  
  func saveToDefaults() {
    let defaults = UserDefaults.standard 
    let perspectiveData = NSKeyedArchiver.archivedData(withRootObject: self.perspective)
    defaults.set(perspectiveData, forKey: current_perspective_key)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    let planeZero: SCNVector3 = renderer.pointOfView!.presentation.convertPosition(SCNVector3Make(0.0, 0.0, 0.0), from: sceneFactory!.plane!)
    let planeOne: SCNVector3 = renderer.pointOfView!.presentation.convertPosition(SCNVector3Make(0.0, 0.0, 1.0), from: sceneFactory!.plane!)
    let normal = SCNVector3Normalize(planeOne - planeZero)
    let d: CGFloat = planeZero.planeDistance(planeNormal: normal)
    self.materialFactory!.clipPlaneNormal = normal
    self.materialFactory!.clipPlaneDistance = d
  }
}

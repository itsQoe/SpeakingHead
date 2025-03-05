//
//  MiniHeadView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 26.08.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import SceneKit

class MiniHeadView: SCNView {
  var api: SCNRenderingAPI?
  
  var sceneFactory: SceneFactory?
  var materialFactory: MaterialFactory?
  
  var sliceFlag: Bool = false
  
  weak var headView: HeadView?
  
  override init(frame: NSRect, options: [String : Any]?) {
    if let api = options?[SCNView.Option.preferredRenderingAPI.rawValue] as? SCNRenderingAPI {
      self.api = api
    }
    
    super.init(frame: frame, options: options)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func flagsChanged(with event: NSEvent) {
    self.headView!.shiftState = event.modifierFlags.contains(NSEvent.ModifierFlags.shift)
  }
  
  override func mouseDown(with event: NSEvent) {
    let p = self.convert(event.locationInWindow, from: nil)
    let testResults = self.hitTest(p, options: [SCNHitTestOption.firstFoundOnly: true])
    if let hitTest = testResults.first {
      if hitTest.node === sceneFactory!.sliceHandle {
        sliceFlag = true
      } else {
        sliceFlag = false
      }
    }
  }
  
  override func scrollWheel(with event: NSEvent) {
    var new_plane = sceneFactory!.plane!.position.z - (event.deltaX+event.deltaY)/100
    let maxBound = CGFloat(1.4)
    if new_plane < -maxBound {new_plane = -maxBound}
    if new_plane > maxBound {new_plane = maxBound}
    sceneFactory!.plane!.position = SCNVector3Make(0.0, 0.0, new_plane)
  }
  
  override func mouseDragged(with event: NSEvent) {
    if sliceFlag {
      var new_plane = sceneFactory!.plane!.position.z + event.deltaX/100 
      let maxBound = CGFloat(1.4)
      if new_plane < -maxBound {new_plane = -maxBound}
      if new_plane > maxBound {new_plane = maxBound}
      sceneFactory!.plane!.position = SCNVector3Make(0.0, 0.0, new_plane)
    } else {
      let new_y = headView!.miniCamNode.eulerAngles.y - event.deltaX/self.frame.width*2
      let new_z = headView!.miniCamNode.eulerAngles.z - event.deltaY/self.frame.width*2
      headView!.miniCamNode.eulerAngles = SCNVector3Make(0.0, new_y, new_z)
      
      sceneFactory!.planeOrbit!.transform = 
        headView!.leftTransform 
        * headView!.miniCamNode.transform 
        * headView!.rightTransform       
    }
  }

}

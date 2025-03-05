//
//  HeadAnimation.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 11.04.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Cocoa
import QuartzCore

class HeadAnimation: NSObject {
  var head: CAAnimationGroup?
  var speed: Float = 1.0
  var duration: CFTimeInterval = 0.0
  
  init(headAnimation headAnim: CAAnimationGroup) {
    super.init()
    head = headAnim
    duration = headAnim.duration
  }
  
  override var description: String {
    return NSString(format: "HeadAnimation: head=%@ speed=%f duration=%f", head?.description ?? "nil", speed, duration) as String
  }
}

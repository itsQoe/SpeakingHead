//
//  SHColoredView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 10.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class SHColoredView: NSView {
  
  @IBInspectable dynamic var view_color: NSColor = NSColor.white
  
  convenience init(frame frameRect: NSRect, color: NSColor) {
    self.init(frame: frameRect)
    view_color = color
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override func draw(_ dirtyRect: NSRect) {
    let path = NSBezierPath(rect: dirtyRect)
    view_color.set()
    path.fill()
    super.draw(dirtyRect)
  }
}

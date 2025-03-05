//
//  SHInfoPanel.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 07.12.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class SHInfoPanel: NSPanel {
  
  var label: NSTextField?
  var text: String = "" {
    didSet {
      label!.stringValue = text
      label!.sizeToFit()
      var windowFrame = self.frame
      windowFrame.size = label!.frame.size
      self.setFrame(windowFrame, display: true, animate: false)
    }
  }
  
  convenience init() {
    self.init(contentRect: NSRect.zero, styleMask: [NSWindow.StyleMask.borderless, NSWindow.StyleMask.hudWindow], backing: .buffered, defer: true)
    self.isFloatingPanel = true
    self.label = NSTextField(frame: NSRect.zero)
    self.label?.isEditable = false
    self.label?.isSelectable = false
    self.contentView?.addSubview(label!)
  }
  
}

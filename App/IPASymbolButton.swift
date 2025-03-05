//
//  IPASymbolButton.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 24.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class IPASymbolButton: NSTextField {
  
  private var savedBackGroundColor: NSColor?
  private var savedTextColor: NSColor?
  @objc dynamic var mouseOverColor: NSColor = NSColor.green
  
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    let opts = NSTrackingArea.Options([NSTrackingArea.Options.activeInActiveApp, NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.mouseEnteredAndExited])
    self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: opts, owner: self, userInfo: nil))
  }
  
  override func mouseDown(with event: NSEvent) {
    if let action = self.action, let target = self.target {
      self.sendAction(action, to: target)
    }
  }
  
  override func mouseEntered(with event: NSEvent) {
    savedBackGroundColor = self.backgroundColor
    savedTextColor = self.textColor
    self.backgroundColor = mouseOverColor
    self.textColor = visibleColor(forBackgroundColor: mouseOverColor, forColor: textColor!)
  }
  
  override func mouseExited(with event: NSEvent) {
    self.backgroundColor = savedBackGroundColor
    self.textColor = savedTextColor
  }
}

//
//  IPACursorView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 10.07.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Cocoa

class IPACursorView: NSView {
  
  var border_width: CGFloat = 2.0
  var border_color: NSColor = NSColor.darkGray
  var blinkTimer: Timer?
  var blinkInterval: TimeInterval = TimeInterval(0.7)
  var ipaSymbol: IPASymbolView?
  
  override init(frame: NSRect) {
    super.init(frame: frame)
    self.wantsLayer = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)    

    let path = NSBezierPath()
    path.move(to: CGPoint(x: border_width/2, y: 0.0))
    path.line(to: CGPoint(x: border_width/2, y: self.bounds.height))
    path.close()
    
    border_color.set()
    path.lineWidth = border_width
    path.stroke()
  }
    
  func activate() {
    self.alphaValue = 1.0
    if let timer = blinkTimer {
      timer.invalidate()
      blinkTimer = nil
    }
    blinkTimer = Timer.scheduledTimer(timeInterval: blinkInterval, 
                                      target: self, 
                                      selector: #selector(toggleBlink), 
                                      userInfo: nil, 
                                      repeats: true)
    
    self.isHidden = false
  }
  
  func deactivate() {
    if let timer = blinkTimer {
      timer.invalidate()
      blinkTimer = nil
    }
    self.isHidden = true
  }
  
  func reset() {
    deactivate()
    activate()
  }
  
  @objc func toggleBlink() {
    if self.alphaValue == 0.0 {
      self.animator().alphaValue = 1.0
    } else {
      self.animator().alphaValue = 0.0
    }
    if self.isHidden {
      ipaSymbol?.needsDisplay = true
    }
  }  
}

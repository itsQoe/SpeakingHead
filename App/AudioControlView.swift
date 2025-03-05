//
//  AudioControlView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 01.03.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import AppKit

class AudioControlView: NSView {
  
  var audioCursorPosition: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var audioCursorWidth: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var audioCursorColor: NSColor = NSColor.black {
    didSet {
      self.needsDisplay = true
    }
  }
  var audioCursorIsHidden: Bool = false {
    didSet {
      self.needsDisplay = true
    }
  }
  
  var mouseCursorPosition: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var mouseCursorWidth: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var mouseCursorColor: NSColor = NSColor.black {
    didSet {
      self.needsDisplay = true
    }
  }
  var mouseCursorIsHidden: Bool = false {
    didSet {
      self.needsDisplay = true
    }
  }
  
  var selectionRange: ClosedRange<CGFloat> = 0.0 ... 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var selectionColor: NSColor = NSColor.selectedTextBackgroundColor {
    didSet {
      self.needsDisplay = true
    }
  }
  var selectionIsHidden: Bool = false {
    didSet {
      self.needsDisplay = true
    }
  }
  
  var baselineHeight: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var baselineWidth: CGFloat = 0.0 {
    didSet {
      self.needsDisplay = true
    }
  }
  var baselineColor: NSColor = NSColor.black {
    didSet {
      self.needsDisplay = true
    }
  }
  var baselineIsHidden: Bool = false {
    didSet {
      self.needsDisplay = true
    }
  }
  
  override func draw(_ dirtyRect: NSRect) {
    let dirtyMinX = dirtyRect.origin.x
    let dirtyMaxX = dirtyMinX + dirtyRect.size.width
        
    if !selectionIsHidden 
      && dirtyMinX <= selectionRange.upperBound
      && dirtyMaxX >= selectionRange.lowerBound {
      let path = NSBezierPath(rect: NSMakeRect(max(selectionRange.lowerBound, dirtyMinX), 
                                               self.bounds.origin.y, 
                                               min(selectionRange.upperBound-selectionRange.lowerBound, dirtyRect.width), 
                                               dirtyRect.height))
      
      selectionColor.withAlphaComponent(0.5).set()
      path.fill()
    }
    
    if !baselineIsHidden {
      let path = NSBezierPath(rect: NSMakeRect(dirtyMinX, baselineHeight, dirtyRect.width, baselineWidth))
      baselineColor.set()
      path.fill()
    }

    if !audioCursorIsHidden 
      && dirtyMinX <= audioCursorPosition
      && dirtyMaxX >= audioCursorPosition {
      let path = NSBezierPath(rect: NSMakeRect(audioCursorPosition, self.bounds.origin.y, audioCursorWidth, self.bounds.height))
      audioCursorColor.set()
      path.fill()
    }
    
    if !mouseCursorIsHidden 
      && dirtyMinX <= mouseCursorPosition
      && dirtyMaxX >= mouseCursorPosition {
      let path = NSBezierPath(rect: NSMakeRect(mouseCursorPosition, self.bounds.origin.y, mouseCursorWidth, self.bounds.height))
      mouseCursorColor.set()
      path.fill()
    }
  }
}

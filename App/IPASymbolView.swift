//
//  IPASymbolView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 27.04.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Cocoa

// @IBDesignable
class IPASymbolView: NSView {
  
  var delegate: IPASymbolViewDelegate?
  
  var phone: Phone?
  
  var nextSymbolView: IPASymbolView?
  
  var hasBorder: Bool = true
  var hasShadow: Bool = false
  var showControls: Bool = false
  var autoHideControls: Bool = true
  
  var hasPrepLine: Bool = true
  var hasSecLine: Bool = false
  
  var infoPanel: SHInfoPanel?
  
  var borderColor: NSColor = NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 1)
  var textColor: NSColor = NSColor.black
  var backgroundColor: NSColor = NSColor.white // NSColor(calibratedRed: 0.85, green: 0.85, blue: 0.85, alpha: 1)
  var selectionColor: NSColor = NSColor.selectedTextBackgroundColor
  
  var prepLineColor: NSColor = NSColor.red
  var secLineColor: NSColor = NSColor.lightGray
  
  var borderWidth: CGFloat = 2.0
  var cornerLength: CGFloat = 10.0
  var sizeGrabWidth: CGFloat = 5.0
  var lineGrabWidth: CGFloat = 3.0
  
  var cornerPath: NSBezierPath?
  
  var max_height: CGFloat = 90.0
  var max_width: CGFloat {
    return CGFloat(max_duration * pixel_per_second)
  }
  
  var min_height: CGFloat = 20.0
  var min_width: CGFloat {
    return CGFloat(min_duration * pixel_per_second)
  }
  
  var max_duration: Double = 3.0
  var min_duration: Double = 0.03
  
  var zoom: Double = 0.0 {
    didSet {
      if zoom != oldValue {
        updateView()
      }
    }
  }
  
  var minPPS: Double = 300.0
  var maxPPS: Double = 1000.0
  var pixel_per_second: Double {
    return minPPS + (maxPPS - minPPS) * zoom
  }
  
  var prep_position: CGFloat = 0.0 {
    didSet {
      if prep_position != oldValue {
        self.needsDisplay = true
      }
    }
  }
  
  var sec_position: CGFloat = 0.0 {
    didSet {
      if prep_position != oldValue {
        self.needsDisplay = true
      }
    }
  }
  
  var isSelected: Bool = false {
    didSet {
      if isSelected != oldValue {
        self.needsDisplay = true
      }
    }
  }
  
  var phoneStr: NSString = ""
  var phoneStrAttr: [NSAttributedStringKey: AnyObject]?
  var infoStrAttr: [NSAttributedStringKey: AnyObject]?
  
  var dragArtFlag = false
  var dragDurFlag = false
  var dragPrepFlag = false
  var dragSecFlag = false
  
  var changedArtFlag = false
  var changedDurFlag = false
  var changedPrepFlag = false
  var changedSecFlag = false
  
  var editMode: Bool = false {
    didSet {
      needsDisplay = true
    }
  }
  
  // MARK: Initialization
  
  convenience init(frame: CGRect, phone: Phone) {
    self.init(frame: frame)
    self.setFrameSize(NSMakeSize(CGFloat(phone.duration * Float(pixel_per_second)), min_height + (max_height - min_height) * CGFloat(phone.articulation)))    
    self.phone = phone
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    setup()
  }
  
  func setup() {
    self.wantsLayer = true
    self.canDrawConcurrently = true
    initStringAttributes()
    if hasShadow {
      let dropShadow = NSShadow()
      dropShadow.shadowColor = NSColor.shadowColor
      dropShadow.shadowOffset = NSMakeSize(3.0, -10.0)
      dropShadow.shadowBlurRadius = 10.0
      self.shadow = dropShadow
    }
  }
  
  override func removeFromSuperview() {
    undoManager?.removeAllActions(withTarget: self)
    super.removeFromSuperview()
  }
  
  // MARK: Update View
  
  func updateView() {
    if let phone = self.phone {
      self.frame.size.width = round(CGFloat((phone.duration) * Float(pixel_per_second)))
      self.frame.size.height = round(CGFloat(phone.articulation) * (self.max_height - self.min_height) + self.min_height)
      prep_position = CGFloat(phone.prep_duration * Float(pixel_per_second))
      sec_position = CGFloat(phone.sec_duration * Float(pixel_per_second))
      
      self.phoneStr = phone.symbol as NSString
    }
  }
  
  // MARK: Setter
  
  func setSymbol(_ newSymbol: String) {
    if let phone = self.phone {
      if let undo = undoManager {
        let oldValue = phone.symbol
        undo.registerUndo(withTarget: self) {targetSelf in
          targetSelf.setSymbol(oldValue)
        }
        if !undo.isUndoing {
          undo.setActionName("IPA Symbol")
        }
      }
      
      self.phone?.symbol = newSymbol
      updateView()
      self.needsDisplay = true
      self.delegate?.phoneDidChange(sender: self)
    }
  }
  
  func setPrepArtDuration(prep: Float, art: Float, factor: Float) {
    if let phone = self.phone {
      if let undo = undoManager {
        let oldPrep = phone.prep_duration
        let oldArt = phone.art_duration
        let oldFactor = phone.articulation
        undo.registerUndo(withTarget: self) {targetSelf in
          targetSelf.setPrepArtDuration(prep: oldPrep, art: oldArt, factor: oldFactor)
        }
      }
      phone.prep_duration = prep
      if !hasSecLine {
        phone.sec_duration = prep
      }
      phone.art_duration = art
      phone.articulation = factor
      self.updateView()
      self.delegate?.phoneDidChange(sender: self)
    }
  }
  
  func updatePrepArtDuration() {
    let newPrepDuration = Float(prep_position) / Float(pixel_per_second)
    let newArtDuration = Float(self.frame.size.width - prep_position) / Float(pixel_per_second)
    let newArticulation = Float((self.frame.size.height - self.min_height) / (self.max_height - self.min_height))
    setPrepArtDuration(prep: newPrepDuration, art: newArtDuration, factor: newArticulation)
  }
  
  func setSecDuration(_ x: Float) {
    if let phone = self.phone {
      if let undo = undoManager {
        let oldValue = phone.sec_duration
        undo.registerUndo(withTarget: self) {targetSelf in
          targetSelf.setSecDuration(oldValue)
        }
      }
      phone.sec_duration = x
      self.updateView()
      self.delegate?.phoneDidChange(sender: self)
    }
  }
  
  func updateSecDuration() {
    let newSecDuration = Float(sec_position) / Float(pixel_per_second)
    setSecDuration(newSecDuration)
  }
  
  // MARK: Calculators
  
  private func getArticulation(_ height: CGFloat) -> Float {
    return Float((height - self.min_height) / (self.max_height - self.min_height))
  }
  
  private func getDuration(_ length: CGFloat) -> Float {
    return Float(length) / Float(pixel_per_second)
  }
  
  // MARK: Initialization
  
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    let opts = NSTrackingArea.Options([NSTrackingArea.Options.activeInActiveApp, NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.mouseEnteredAndExited])
    self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: opts, owner: self, userInfo: nil))
  }
  
  func initStringAttributes() {
    let style = NSMutableParagraphStyle()
    style.alignment = NSTextAlignment.center
    let phoneAttr = [NSAttributedStringKey.paragraphStyle: style,
                     NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 16.0)]
    phoneStrAttr = phoneAttr
    
    let infoAttr = [NSAttributedStringKey.paragraphStyle: style,
                    NSAttributedStringKey.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
    infoStrAttr = infoAttr
  }
  
  // MARK: Drawing
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    self.drawBorder(dirtyRect)
    
    if showControls {
      if hasPrepLine && prep_position > 0.0 {
        self.drawLine(prep_position, color: prepLineColor)
      }
      if hasSecLine && sec_position > 0.0 {
        self.drawLine(sec_position, color: secLineColor)
      }
      drawTriangle(dirtyRect)
    }
    drawChar(dirtyRect)
  }
  
  func drawBorder(_ rect: NSRect) {
    let newRect = NSMakeRect(round(self.bounds.origin.x+borderWidth/2), 
                             round(self.bounds.origin.y+borderWidth/2), 
                             self.bounds.size.width-borderWidth, 
                             self.bounds.size.height-borderWidth)
    let viewSurround = NSBezierPath(roundedRect: newRect, xRadius: 1.0, yRadius: 1.0)
    
    if isSelected {
      self.selectionColor.set()
    } else {
      self.backgroundColor.set()
    }
    viewSurround.fill()
    
    viewSurround.lineWidth = borderWidth
    borderColor.set()
    viewSurround.stroke()
  }
  
  func drawLine(_ x: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    path.move(to: NSMakePoint(self.bounds.origin.x+x, self.bounds.origin.y + borderWidth))
    path.line(to: NSMakePoint(self.bounds.origin.x+x, self.bounds.origin.y+self.bounds.height - borderWidth))
    path.close()
    
    color.set()
    path.lineWidth = borderWidth
    path.stroke()
  }
  
  func drawTriangle(_ rect: NSRect) {
    let path = NSBezierPath()
    path.move(to: NSMakePoint(self.bounds.origin.x+self.bounds.width-cornerLength, self.bounds.origin.y+self.bounds.height))
    path.line(to: NSMakePoint(self.bounds.origin.x+self.bounds.width, self.bounds.origin.y+self.bounds.height-cornerLength))
    path.line(to: NSMakePoint(self.bounds.origin.x+self.bounds.width, self.bounds.origin.y+self.bounds.height))
    path.line(to: NSMakePoint(self.bounds.origin.x+self.bounds.width-cornerLength, self.bounds.origin.y+self.bounds.height))
    path.close()
    cornerPath = path
    borderColor.set()
    path.fill()
  }
    
  func drawChar(_ rect: NSRect) {
    let strSize = phoneStr.size(withAttributes: phoneStrAttr)
    let frameRect = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y+(self.bounds.height-strSize.height)/2, self.bounds.width, strSize.height)
    if isSelected {
      phoneStrAttr?[NSAttributedStringKey.foregroundColor] = visibleColor(forBackgroundColor: selectionColor, forColor: textColor)
    } else {
      phoneStrAttr?[NSAttributedStringKey.foregroundColor] = textColor
    }
    if !editMode {
      phoneStr.draw(in: frameRect, withAttributes: phoneStrAttr)
    } else {
      "?".draw(in: frameRect, withAttributes: phoneStrAttr)
    }
  }
  
  // MARK: Mouse
  
  override func mouseDown(with event: NSEvent) {
    let p = self.convert(event.locationInWindow, from: nil)
    if cornerPath!.contains(p) {
      dragArtFlag = true
      dragDurFlag = true
      undoManager?.beginUndoGrouping()
      if let undo = undoManager, !undo.isUndoing {
        undo.setActionName("Articulation & Duration")
      }
    } else if p.y > self.frame.size.height - sizeGrabWidth {
      dragArtFlag = true
      undoManager?.beginUndoGrouping()
      if let undo = undoManager, !undo.isUndoing {
        undo.setActionName("Articulation Factor")
      }
    } else if p.x > self.frame.size.width - sizeGrabWidth {
      dragDurFlag = true
      undoManager?.beginUndoGrouping()
      if let undo = undoManager, !undo.isUndoing {
        undo.setActionName("Articulation Duration")
      }
    } else if hasPrepLine && p.x < prep_position + lineGrabWidth && p.x > prep_position - lineGrabWidth {
      dragPrepFlag = true
      undoManager?.beginUndoGrouping()
      if let undo = undoManager, !undo.isUndoing {
        undo.setActionName("Preparation Duration")
      }
    } else if hasSecLine && p.x < sec_position + lineGrabWidth && p.x > sec_position - lineGrabWidth {
      dragSecFlag = true
      undoManager?.beginUndoGrouping()
      if let undo = undoManager, !undo.isUndoing {
        undo.setActionName("Secondary Preparation Duration")
      }
    } else {
      super.mouseDown(with: event)
    }
  }
  
  func updatePhone() {
    if changedArtFlag || changedDurFlag || changedPrepFlag {
      updatePrepArtDuration()
      changedArtFlag = false
      changedDurFlag = false
      changedPrepFlag = false
    }
    if changedSecFlag {
      updateSecDuration()
      changedSecFlag = false
    }
    dragArtFlag = false
    dragDurFlag = false
    dragPrepFlag = false
    dragSecFlag = false
  }
  
  override func mouseUp(with event: NSEvent) {
    if dragArtFlag || dragDurFlag || dragPrepFlag || dragSecFlag {
      self.updatePhone()
      self.nextSymbolView?.updatePhone()
      undoManager?.endUndoGrouping()
      NSCursor.arrow.set()
      infoPanel?.orderOut(self)
      
      let p = self.convert(event.locationInWindow, from: nil)
      if autoHideControls && !NSPointInRect(p, self.bounds) {
        showControls = false
        needsDisplay = true
      }
    } else {
      super.mouseUp(with: event)
    }
  }
  
  override func mouseMoved(with event: NSEvent) {
    showControls = true
    let p = self.convert(event.locationInWindow, from: nil)
    if p.y >= self.frame.size.height - sizeGrabWidth {
      NSCursor.resizeUpDown.set()
      infoPanel?.text = String.localizedStringWithFormat("%.0f %%", phone!.articulation*100)
      let infoPoint = self.convert(NSMakePoint(0.0, self.frame.size.height), to: nil)
      infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: infoPoint, size: CGSize.zero)).origin)
      if let infoPanel = self.infoPanel, !infoPanel.isVisible { infoPanel.orderFront(self) }
    } else if p.x >= self.frame.size.width - sizeGrabWidth {
      NSCursor.resizeLeftRight.set()
      infoPanel?.text = String.localizedStringWithFormat("%.3f s", phone!.art_duration)
      let infoPoint = self.convert(NSMakePoint(self.frame.size.width, 0.0), to: nil)
      infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: infoPoint, size: CGSize.zero)).origin)
      if let infoPanel = self.infoPanel, !infoPanel.isVisible { infoPanel.orderFront(self) }
    } else if hasPrepLine && p.x <= prep_position + lineGrabWidth && p.x >= prep_position - lineGrabWidth {
      NSCursor.resizeLeftRight.set()
      infoPanel?.text = String.localizedStringWithFormat("%.3f s", phone!.prep_duration)
      let infoPoint = self.convert(NSMakePoint(prep_position, 0.0), to: nil)
      infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: infoPoint, size: CGSize.zero)).origin)
      if let infoPanel = self.infoPanel, !infoPanel.isVisible { infoPanel.orderFront(self) }
    } else if hasSecLine && p.x <= sec_position + lineGrabWidth && p.x >= sec_position - lineGrabWidth {
      NSCursor.resizeLeftRight.set()
      infoPanel?.text = String.localizedStringWithFormat("%.3f s", phone!.sec_duration)
      let infoPoint = self.convert(NSMakePoint(sec_position, 0.0), to: nil)
      infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: infoPoint, size: CGSize.zero)).origin)
      if let infoPanel = self.infoPanel, !infoPanel.isVisible { infoPanel.orderFront(self) }
    } else {
      NSCursor.arrow.set()
      infoPanel?.orderOut(self)
    }
  }
  
  override func mouseEntered(with event: NSEvent) {
    if autoHideControls && !dragArtFlag && !dragDurFlag {
      showControls = true
      needsDisplay = true
    }
  }
  
  override func mouseExited(with theEvent: NSEvent) {
    if !dragArtFlag && !dragDurFlag && !dragPrepFlag && !dragSecFlag {
      NSCursor.arrow.set()
      infoPanel?.orderOut(self)
      if autoHideControls {
        showControls = false
        needsDisplay = true
      }
    }
  }
  
  func add(width: CGFloat) {
    self.dragDurFlag = true
    self.calculate(width: self.frame.size.width + width, height: self.frame.size.height)
  }
  
  func calculate(width: CGFloat, height: CGFloat) {
    var newSize = NSMakeSize(
      dragDurFlag ? width : self.frame.size.width,
      dragArtFlag ? height : self.frame.size.height
    )
    
    if newSize.width > max_width {newSize.width = max_width}
    if newSize.width < min_width {newSize.width = min_width}
    if newSize.height > max_height {newSize.height = max_height}
    if newSize.height < min_height {newSize.height = min_height}
    
    // Update preparation duration
    var newPrepPosition = (self.prep_position / self.bounds.width) * newSize.width
    if newPrepPosition < borderWidth {
      newPrepPosition = borderWidth
    } else if newPrepPosition > newSize.width - 2*borderWidth {
      newPrepPosition = newSize.width - 2*borderWidth
    }
    self.prep_position = newPrepPosition
    self.changedPrepFlag = true
    
    self.setFrameSize(newSize)
  }
  
  override func mouseDragged(with event: NSEvent) {
    let p = self.convert(event.locationInWindow, from: nil)
    if dragArtFlag || dragDurFlag {
      if (dragDurFlag && p.x > min_width && p.x < max_width) {
        self.nextSymbolView?.add(width: self.frame.size.width - p.x)
      }
      calculate(width: p.x, height: p.y)
      
      if dragArtFlag { changedArtFlag = true }
      if dragDurFlag { changedDurFlag = true }
        
      var infoPoint: NSPoint?
      if dragArtFlag && dragDurFlag {
        infoPanel?.text = String.localizedStringWithFormat("%.0f %%\n%.2f s", getArticulation(self.frame.size.height)*100, getDuration(self.frame.size.width))
        infoPoint = self.convert(NSMakePoint(self.frame.size.width, self.frame.size.height), to: nil)
      } else if dragArtFlag {
        infoPanel?.text = String.localizedStringWithFormat("%.0f %%", getArticulation(self.frame.size.height)*100)
        infoPoint = self.convert(NSMakePoint(0.0, self.frame.size.height), to: nil)
      } else if dragDurFlag {
        infoPanel?.text = String.localizedStringWithFormat("%.3f s", getDuration(self.frame.size.width))
        infoPoint = self.convert(NSMakePoint(self.frame.size.width, 0.0), to: nil)
      }
      infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: infoPoint!, size: CGSize.zero)).origin)
      if let infoPanel = self.infoPanel, !infoPanel.isVisible { 
        infoPanel.orderFront(self)
      }
      delegate?.phoneDidResize?(sender: self)
    } else if dragPrepFlag {
      var new_position = p.x // prep_position + event.deltaX
      if new_position < borderWidth {
        new_position = borderWidth
      } else if new_position > self.bounds.width - 2*borderWidth {
        new_position = self.bounds.width - 2*borderWidth
      }
      prep_position = new_position
      changedPrepFlag = true
      if sec_position < prep_position + borderWidth {
        sec_position = prep_position + borderWidth
        changedSecFlag = true
      }
      
      infoPanel?.text = String.localizedStringWithFormat("%.3f s", getDuration(new_position))
      let infoPoint = self.convert(NSMakePoint(prep_position, 0.0), to: nil)
      infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: infoPoint, size: CGSize.zero)).origin)
      if let infoPanel = self.infoPanel, !infoPanel.isVisible {
        infoPanel.orderFront(self)
      }
    } else if dragSecFlag {
      var new_position = p.x
      if new_position < 2 * borderWidth {
        new_position = 2 * borderWidth
      } else if new_position > self.bounds.width - borderWidth {
        new_position = self.bounds.width - borderWidth
      }
      sec_position = new_position
      changedSecFlag = true
      if prep_position > sec_position - borderWidth {
        prep_position = sec_position - borderWidth
        changedPrepFlag = true
      }
      
      infoPanel?.text = String.localizedStringWithFormat("%.3f s", getDuration(new_position))
      let infoPoint = self.convert(NSMakePoint(sec_position, 0.0), to: nil)
      infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: infoPoint, size: CGSize.zero)).origin)
      if let infoPanel = self.infoPanel, !infoPanel.isVisible {
        infoPanel.orderFront(self)
      }
    } else {
      infoPanel?.orderOut(self)
      super.mouseDragged(with: event)
      return
    }
  }
}

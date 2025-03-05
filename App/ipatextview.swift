//
//  IPATextView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 30.04.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Cocoa

private var KVOContext: Int = 0

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// @IBDesignable
class IPATextView: NSView, NSTextInputClient, IPASymbolViewDelegate {
  
  var delegate: IPATextViewDelegate?
  
  var animFactory: AnimationFactory?
  
  @objc dynamic var zoom: Double = 0.0 {
    didSet {
      updateSubViews(manipulatedView: nil)
    }
  }
  var minPPS: Double = 300.0
  var maxPPS: Double = 1000.0
  var pixel_per_second: Double {
    return minPPS + (maxPPS - minPPS) * zoom
  }
  
  var phones = [Phone]()
  var symbolViews = [IPASymbolView]()
  var cursorView: IPACursorView?
  
  var infoPanel: SHInfoPanel?
  
  @IBInspectable var autoPopover: Bool = true
  
  var defaultPhone = Phone()
  var editSymbolView: IPASymbolView?
  var editPos: Int?
  
  var inSelectionCursorPosition = 0
  var inSelectionFlag = false
  var dragTextFlag = false
  var dragText: String = ""
  
  var textRange: ClosedRange<CGFloat> = 0.0 ... 0.0
  var minimalFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
  
  var cursorWidth: CGFloat = 1.0
  @objc dynamic var cursorColor: NSColor = NSColor.darkGray {
    didSet {
      cursorView?.border_color = cursorColor
      cursorView?.needsDisplay = true
    }
  }
  @objc dynamic var selectionColor: NSColor = NSColor.selectedTextBackgroundColor {
    didSet {
      for view in symbolViews {
        view.selectionColor = selectionColor
        if view.isSelected {
          view.needsDisplay = true
        }
      }
    }
  }
  
  @objc dynamic var primaryIndicatorColor: NSColor = NSColor.red {
    didSet {
      for view in symbolViews {
        view.prepLineColor = primaryIndicatorColor
        view.needsDisplay = true
      }
    }
  }
  
  @objc dynamic var secondaryIndicatorColor: NSColor = NSColor.red {
    didSet {
      for view in symbolViews {
        view.secLineColor = secondaryIndicatorColor
        view.needsDisplay = true
      }
    }
  }
  
  var selection: CountableRange<Int> = 0 ..< 0 {
    didSet {
      if selection.lowerBound < selection.upperBound {
        cursorView?.deactivate()
        
        if oldValue.lowerBound != selection.lowerBound && selection.lowerBound < symbolViews.count {
          manipulationAt = symbolViews[selection.lowerBound].frame.origin.x
        } else if oldValue.upperBound != selection.upperBound 
          && selection.upperBound <= symbolViews.count 
          && selection.upperBound > 0 
        {
          let upperView = symbolViews[selection.upperBound-1]
          manipulationAt = upperView.frame.origin.x + upperView.frame.size.width
        }
      } else {
        cursorView?.reset()
      }
      
      var c = 0
      for view in symbolViews {
        view.isSelected = selection.contains(c)
        c += 1
      }
    }
  }
  
  var isSelected: Bool {
    return selection.lowerBound != selection.upperBound
  }
    
  var cursorPosition: Int = 0 {
    didSet {
      if cursorPosition != oldValue && cursorView != nil {
        var cursorX: CGFloat = 0.0
        if cursorPosition > 0 {
          for i in 0..<min(cursorPosition, symbolViews.count) {
            cursorX += symbolViews[i].frame.size.width
          }
        }
        cursorView!.frame.origin.x = cursorX
        if cursorPosition < symbolViews.count {
          cursorView?.ipaSymbol = symbolViews[cursorPosition]
        } else {
          cursorView?.ipaSymbol = nil
        }
        if oldValue < symbolViews.count {
          symbolViews[oldValue].needsDisplay = true
        }
        manipulationAt = cursorView!.frame.origin.x
        cursorView?.reset()
      }
    }
  }
  
  var manipulationAt: CGFloat = 0.0
  
  // MARK: Initialization
  
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
    minimalFrame = self.frame
    self.autoresizesSubviews = false
    cursorView = IPACursorView(frame: NSMakeRect(0.0, 0.0, cursorWidth, self.frame.size.height))
    cursorView!.border_width = self.cursorWidth
    cursorView!.border_color = self.cursorColor
    cursorView!.deactivate()
    self.addSubview(cursorView!, positioned: .above, relativeTo: nil)
    self.infoPanel = SHInfoPanel()
  }
  
  // MARK: First Responder
  
  override var acceptsFirstResponder: Bool {
    return true 
  }
  
  override func becomeFirstResponder() -> Bool {
    if !isSelected {
      cursorView?.reset()
    }
    if autoPopover {
      self.delegate?.requestPopover(self)
    }
    return true
  }
  
  override func resignFirstResponder() -> Bool {
    cursorView?.deactivate()
    return true
  }
  
  override func keyDown(with event: NSEvent) {
    self.interpretKeyEvents([event])
  }
  
  // MARK: Drawing
  
  func drawBorder(_ rect: NSRect) {
    let frameRect = self.bounds
    
    if rect.size.height < frameRect.size.height {return}
    
    let newRect = NSMakeRect(rect.origin.x+1, rect.origin.y+1, rect.size.width-2, rect.size.height-2)
    let viewSurround = NSBezierPath(roundedRect: newRect, xRadius: 10.0, yRadius: 10.0)
    
    viewSurround.lineWidth = 1.0
    viewSurround.stroke()
  }
  
  func drawCursor(_ rect: NSRect) {
    var cursorX: CGFloat = 0.0
    if cursorPosition > 0 {
      for i in 0..<cursorPosition {
        cursorX += symbolViews[i].frame.size.width
      }
    }
    let path = NSBezierPath()
    path.move(to: NSMakePoint(cursorX, 0.0))
    path.line(to: NSMakePoint(cursorX, rect.size.height))
    path.close()
    cursorColor.set()
    path.lineWidth = cursorWidth
    path.stroke()
  }

  // MARK: Subview Management
    
  func updateSubViews(manipulatedView: IPASymbolView?) {
    var s: Double = 0.0
    var x: CGFloat = 0.0
    var c: Int = 0
    var cursorX: CGFloat = 0.0
    var lastView: IPASymbolView?
    for view in symbolViews {
      if view.zoom == self.zoom {
        view.frame.origin.x = x 
      } else {
        view.frame.origin.x = CGFloat(s * pixel_per_second)
        view.zoom = self.zoom
      }
      if c == cursorPosition-1 {
        cursorX = view.frame.origin.x + view.frame.size.width
      }
      lastView?.nextSymbolView = view
      lastView = view
      s += Double(view.phone?.duration ?? 0.0)
      x += view.frame.width
      c += 1
    }
    lastView?.nextSymbolView = nil
    if let cursorView = self.cursorView {
      cursorView.frame.origin.x = cursorX
    }
    textRange = textRange.lowerBound ... x
    self.frame.size.width = max(minimalFrame.size.width, textRange.upperBound + 50.0)
    if let view = manipulatedView {
      manipulationAt = view.frame.origin.x + view.frame.width
    }
  }
  
  // MARK: Delegate Methods
  
  func phoneDidChange(sender: IPASymbolView) {
    self.updateSubViews(manipulatedView: sender)
    self.delegate?.textDidChange(sender: self)
  }
  
  func phoneDidResize(sender: IPASymbolView) {
    self.updateSubViews(manipulatedView: sender)
    self.delegate?.textDidResize?(sender: self)
  }

  // MARK: Pastebard
  
  func ipaString(inRange range: CountableRange<Int>) -> String {
    var str = String()
    for i in range {
      str += phones[i].ipaString
    }
    return str
  }
  
  func writeToPasteboard(_ pasteboard: NSPasteboard) {
    if isSelected {
      let str = ipaString(inRange: selection)
      pasteboard.clearContents()
      pasteboard.writeObjects([str as NSPasteboardWriting, ])
    }
  }
  
  func readFromPasteboard(_ pasteboard: NSPasteboard) {
    if let objects = pasteboard.readObjects(forClasses: [NSString.self], options: [:]) as? [String] {
      if objects.count > 0 {
        insertText(objects[0], replacementRange: NSMakeRange(NSNotFound, 0))
      }
    }
  }
  
  @IBAction func cut(_ sender: AnyObject?) {
    if isSelected {
      let pasteboard = NSPasteboard.general
      self.writeToPasteboard(pasteboard)
      self.deleteBackward(sender)
    }
  }
  
  @IBAction func copy(_ sender: AnyObject?) {
    let pasteboard = NSPasteboard.general
    self.writeToPasteboard(pasteboard)
  }
  
  @IBAction func paste(_ sender: AnyObject?) {
    let pasteboard = NSPasteboard.general
    self.readFromPasteboard(pasteboard)
  }
    
  // MARK: Mouse Events
  
  override func mouseUp(with event: NSEvent) {
    if isSelected {
      if inSelectionFlag && !dragTextFlag {
        cursorPosition = inSelectionCursorPosition
        selection = cursorPosition ..< cursorPosition
        inSelectionFlag = false
      } else if dragTextFlag {
        dragTextFlag = false
      }
    }
  }
  
  override func mouseDown(with event: NSEvent) {
    let p = self.convert(event.locationInWindow, from: nil)
    var pos: Int = 0
    for view in symbolViews {
      if view.frame.origin.x + view.frame.size.width < p.x {
        pos += 1
      } else {
        break
      }
    }
    if event.clickCount == 1 {
      if isSelected && selection.contains(pos) {
        inSelectionFlag = true
        inSelectionCursorPosition = pos
      } else {
        inSelectionFlag = false
        selection = pos ..< pos
        cursorPosition = pos
      }
    } else if event.clickCount == 2 && pos < symbolViews.count {
      self.editPos = pos
      let editSymbol = symbolViews[pos]
      editSymbol.editMode = true
      
      if let oldEditView = editSymbolView {
        oldEditView.editMode = false
      }
      editSymbolView = editSymbol
      if autoPopover {
        delegate?.requestPopover(self)
      }
    }
  }
  
  override func mouseDragged(with event: NSEvent) {
    if symbolViews.count > 0 {
      let dragIndex = characterIndex(for: event.locationInWindow)
      selection = min(cursorPosition, dragIndex) ..< max(cursorPosition, dragIndex)
      delegate?.updatePosition(at: event.locationInWindow.x)
    }
  }
    
  // MARK: NSTextInputClient Protocol
  
  func hasMarkedText() -> Bool {
    return false
  }
  
  func markedRange() -> NSRange {
    return NSRange(location: NSNotFound, length: 0)
  }
  
  func selectedRange() -> NSRange {
    return NSRange(location: NSNotFound, length: 0)
  }
  
  func setMarkedText(_ aString: Any, selectedRange: NSRange, replacementRange: NSRange) {
  }
  
  func unmarkText() {
  }
  
  func validAttributesForMarkedText() -> [NSAttributedStringKey] {
    return [NSAttributedStringKey]()
  }
  
  func attributedSubstring(forProposedRange aRange: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
    let countableRange = aRange.location ..< aRange.location + aRange.length
    return NSAttributedString(string: ipaString(inRange:countableRange))
  }
  
  func insertText(_ aString: Any, replacementRange: NSRange) {
    if let str = aString as? String {
      let insertPhones = getPhones(str, lastPhone: nil, defaultPhone: defaultPhone)
      if !isSelected {
        self.insert(phones: insertPhones, inRange: cursorPosition ..< cursorPosition)
      } else {
        self.insert(phones: insertPhones, inRange: selection)
      }
    }
  }
  
  func insertIPASymbol(_ notification: Notification) {
    if let symbol = notification.object as? String {
      insertText(symbol, replacementRange: NSMakeRange(-1, 0))
    }
  }
  
  func getPhones(_ symbols: String, lastPhone: Phone?, defaultPhone: Phone?) -> [Phone] {
    guard self.animFactory != nil else {
      return [Phone]()
    }

    var newPhoneList = [Phone]()
    var errorChars = Set<String>()
    for char in symbols {
      do {
        if let phone = try animFactory?.getPhone(String(char), lastPhone: lastPhone, defaultPhone: defaultPhone) {
          newPhoneList.append(phone)
        }
      } catch IPAError.notAnIPACharacter(let errorChar) {
        errorChars.insert(errorChar)
      } catch {
        errorChars.insert(String(char))
      }
    }
    
    if errorChars.count == 1 {
      let message = "The character '\(errorChars.first!)' is not part of the available IPA characters!"
      delegate?.errorMessage(sender: self, message: message)
    } else if errorChars.count > 1 {
      let message = "The characters '\(errorChars.joined(separator: ", "))' are not part of the available IPA characters!"
      delegate?.errorMessage(sender: self, message: message)
    }
    
    return newPhoneList
  }
  
  func insert(phones phoneList: [Phone]?, inRange r: CountableRange<Int>, undo undoFlag: Bool = true) {
    var firstModifiedView: IPASymbolView?
    
    if let phoneList = phoneList {
      guard self.phones.count < 1000 else {
        delegate?.errorMessage(sender: self, message: "More than 1000 IPA characters are not supported.")
        return
      }

      var newSymbolViews = [IPASymbolView]()
      for phone in phoneList {
        if let edit = editSymbolView {
          edit.editMode = false
          editSymbolView = nil
          edit.setSymbol(phone.symbol)
          return
        } else {
          let newSymbolView = IPASymbolView(frame: CGRect(origin: self.bounds.origin, size: CGSize.zero), phone: phone)
          newSymbolView.minPPS = self.minPPS
          newSymbolView.maxPPS = self.maxPPS
          newSymbolView.zoom = self.zoom
          newSymbolView.selectionColor = self.selectionColor
          newSymbolView.prepLineColor = self.primaryIndicatorColor
          newSymbolView.secLineColor = self.secondaryIndicatorColor
          newSymbolView.max_height = self.frame.size.height
          newSymbolView.infoPanel = self.infoPanel
          newSymbolView.delegate = self
          if phone.symbol == " " {
            newSymbolView.hasPrepLine = false
            newSymbolView.hasSecLine = false
          }
          newSymbolView.updateView()
          newSymbolViews.append(newSymbolView)
          addSubview(newSymbolView)
        }
      }
      
      guard !newSymbolViews.isEmpty else {
        return
      }
      
      firstModifiedView = newSymbolViews[0]
      
      if r.lowerBound == r.upperBound {
        // insert at index
        if let undo = undoManager, undoFlag {
          undo.registerUndo(withTarget: self) {targetSelf in
            targetSelf.insert(phones: nil, inRange: r.lowerBound ..< r.lowerBound + phoneList.count)
            targetSelf.cursorPosition = self.cursorPosition
            targetSelf.selection = self.selection
          }
          if !undo.isUndoing {
            undo.setActionName("Insert")
          }
        }
        
        phones.insert(contentsOf: phoneList, at: r.lowerBound)
        symbolViews.insert(contentsOf: newSymbolViews, at: r.lowerBound)
        cursorPosition = r.lowerBound + phoneList.count
      } else {
        // replace selection
        if let undo = undoManager, undoFlag {
          let undoPhones = Array(self.phones[r])
          undo.registerUndo(withTarget: self) {targetSelf in
            targetSelf.insert(phones: undoPhones, inRange: r.lowerBound ..< r.lowerBound + phoneList.count)
            targetSelf.cursorPosition = self.cursorPosition
            targetSelf.selection = self.selection
          }
          if !undo.isUndoing {
            undo.setActionName("Insert")
          }
        }
        
        phones.replaceSubrange(r, with: phoneList)
        symbolViews.replaceSubrange(r, with: newSymbolViews)
        selection = r.lowerBound ..< r.lowerBound + phoneList.count
      }
    } else if r.lowerBound < r.upperBound && r.upperBound <= phones.count {
      // Undo delete
      if let undo = undoManager, undoFlag {
        let undoPhones = Array(self.phones[r])
        undo.registerUndo(withTarget: self) {targetSelf in
          targetSelf.insert(phones: undoPhones, inRange: r.lowerBound ..< r.lowerBound)
          targetSelf.cursorPosition = self.cursorPosition
          targetSelf.selection = self.selection
        }
        if !undo.isUndoing {
          undo.setActionName("Delete")
        }
      }
      
      phones.removeSubrange(r)
      symbolViews.removeSubrange(r)
      cursorPosition = r.lowerBound
      selection = cursorPosition ..< cursorPosition
      if cursorPosition < phones.count {
        firstModifiedView = symbolViews[cursorPosition]
      } else if cursorPosition > 0 {
        firstModifiedView = symbolViews[cursorPosition - 1]
      }
    }
    
    self.subviews = symbolViews
    self.addSubview(cursorView!, positioned: .above, relativeTo: nil)
    updateSubViews(manipulatedView: firstModifiedView)
    delegate?.textDidChange(sender: self)
  }

  func reset(_ sender: Any, withPhones new: [Phone]?) {
    insert(phones: new, inRange: 0 ..< phones.count)
    self.selection = 0 ..< 0
    self.cursorPosition = 0
  }
  
  // MARK: Delete
  
  override func deleteBackward(_ sender: Any?) {
    if isSelected {
      self.insert(phones: nil, inRange: selection)
    } else if cursorPosition > 0 {
      self.insert(phones: nil, inRange: cursorPosition - 1 ..< cursorPosition)
    } else {
      NSSound.beep()
    }
  }
  
  override func deleteForward(_ sender: Any?) {
    if isSelected {
      self.insert(phones: nil, inRange: selection)
    } else if cursorPosition < phones.count {
      self.insert(phones: nil, inRange: cursorPosition ..< cursorPosition+1)
    } else {
      NSSound.beep()
    }
  }
  
  override func deleteToEndOfLine(_ sender: Any?) {
    if cursorPosition < phones.count - 1 && !isSelected {
      self.insert(phones: nil, inRange: cursorPosition + 1 ..< phones.count)
    } else if isSelected {
      self.insert(phones: nil, inRange: selection)
    } else {
      NSSound.beep()
    }
  }
  
  override func deleteToBeginningOfLine(_ sender: Any?) {
    if cursorPosition > 0 && !isSelected {
      self.insert(phones: nil, inRange: 0 ..< cursorPosition+1)
    } else if isSelected {
      self.insert(phones: nil, inRange: selection)
    } else {
      NSSound.beep()
    }
  }
  
  // MARK: Navigate
  
  override func moveLeft(_ sender: Any?) {
    if cursorPosition > 0 && !isSelected {
      cursorPosition -= 1
      self.needsDisplay = true
    } else if isSelected {
      cursorPosition = selection.lowerBound
      selection = cursorPosition ..< cursorPosition 
    } else {
      NSSound.beep()
    }
  }
  
  override func moveLeftAndModifySelection(_ sender: Any?) { 
    if isSelected && selection.lowerBound > 0 {
      if cursorPosition > selection.lowerBound {
        selection = selection.lowerBound - 1 ..< selection.upperBound
      } else {
        selection = selection.lowerBound ..< selection.upperBound - 1
      }
    } else if !isSelected && cursorPosition > 0 {
      selection = cursorPosition - 1 ..< cursorPosition
    } else {
      NSSound.beep()
    }
  }
  
  override func moveRight(_ sender: Any?) {
    if cursorPosition < phones.count && !isSelected {
      cursorPosition += 1
      self.needsDisplay = true
    } else if isSelected {
      cursorPosition = selection.upperBound
      selection = cursorPosition ..< cursorPosition 
    } else {
      NSSound.beep()
    }
  }
  
  override func moveRightAndModifySelection(_ sender: Any?) { 
    if isSelected && selection.upperBound < phones.count {
      if cursorPosition < selection.upperBound {
        selection = selection.lowerBound ..< selection.upperBound + 1
      } else {
        selection = selection.lowerBound + 1 ..< selection.upperBound
      }
    } else if !isSelected && cursorPosition < phones.count {
      selection = cursorPosition ..< cursorPosition + 1
    } else {
      NSSound.beep()
    }
  }
  
  override func selectAll(_ sender: Any?) {
    selection = 0 ..< phones.count
  }
  
  func characterIndex(for aPoint: NSPoint) -> Int {
    if symbolViews.count > 0 {
      let p = self.convert(aPoint, from: nil)
      var pos: Int = 0
      for view in symbolViews {
        if view.frame.origin.x + view.frame.size.width/2 < p.x {
          pos += 1
        } else {
          break
        }
      }
      return pos 
    }
    return 0
  }
  
  func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
    return NSMakeRect(0, 0, 0, 0)
  }
    
  func attributedString() -> NSAttributedString {
    return NSAttributedString(string: ipaString(inRange: 0 ..< phones.count))
  }
  
}

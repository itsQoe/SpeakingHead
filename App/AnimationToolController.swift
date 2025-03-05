//
//  AnimationToolController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 06.01.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import AppKit

class AnimationToolController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, IPASymbolsDelegate {
  
  @IBOutlet weak var ipaTextField: NSTextField?
  @IBOutlet weak var modeTextField: NSTextField?
  @IBOutlet weak var table: NSTableView?
  @IBOutlet weak var ipaPopover: NSPopover?
  @IBOutlet weak var switchButton: NSButton?
  
  weak var sceneFactory: SceneFactory?
  weak var animFactory: AnimationFactory?
  weak var animController: AnimationController?
  
  var phoneAnim: PhoneAnimation? {
    didSet {
      if let phone = phoneAnim {
        modeTextField?.stringValue = phone.mode
        table?.reloadData()
        updateAnimKeyMap()
      }
    }
  }
  
  var animKeyMap: [String: AnimKey] = [String: AnimKey]() 
  
  var ipaSymbol: String? {
    didSet {
      if let symbol = ipaSymbol {
        phoneAnim = animFactory!.phoneAnimDict[symbol]
        ipaTextField?.stringValue = symbol
      }
    }
  }
  
  var artFactor: NSNumber = NSNumber(value: 1.0) {
    didSet {
      updateHead()
    }
  }
  
  var prepFlag: Bool = true {
    didSet {
      updateAnimKeyMap()
    }
  }
  var secFlag: Bool = true {
    didSet {
      updateAnimKeyMap()
    }
  }
  var artFlag: Bool = true {
    didSet {
      updateAnimKeyMap()
    }
  }
  
  var selectedSection: String = "Prep" {
    didSet {
      
      if selectedSection == "Art" {
        switchButton?.isHidden = true
      } else {
        switchButton?.isHidden = false
      }
      
      table?.reloadData()
    }
  }
  
  override var windowNibName: NSNib.Name? {
    return NSNib.Name("AnimationTool")
  }
  
  override func windowDidLoad() {
    
  }
  
  // MARK: Update head animation
  
  func updateAnimKeyMap() {
    guard let phoneAnim = phoneAnim else {
      return
    }
    
    animKeyMap = [String: AnimKey]()
    
    if prepFlag {
      for animKey in phoneAnim.prepAnimation {
        animKeyMap[animKey.target] = animKey
      }
    }
    if secFlag {
      for animKey in phoneAnim.secAnimation {
        animKeyMap[animKey.target] = animKey
      }
    }
    if artFlag {
      for animKey in phoneAnim.artAnimation {
        animKeyMap[animKey.target] = animKey
      }
    }
    updateHead()
  }
  
  //  func updateAnimFactory() {
  //    guard let phone = phone, let animFactory = animFactory else {
  //      return
  //    }
  //    animFactory.setPhone(phone)
  //  }
  
  func updateHead() {
    guard let morphTargetList = sceneFactory?.morphTargetList else {
      return
    }
    
    animController?.stopAnimation()
    
    var c: Int = 0
    for morphTarget in morphTargetList {
      if let animKey = animKeyMap[morphTarget] {
        let weight = animKey.minValue + (animKey.maxValue - animKey.minValue) * artFactor.floatValue
        sceneFactory?.head?.morpher?.setWeight(CGFloat(weight), forTargetAt: c)
      } else {
        sceneFactory?.head?.morpher?.setWeight(0.0, forTargetAt: c)
      }
      c += 1
    }
  }
  
  func getAnimKey(forRow row: Int) -> AnimKey? {
    guard let phoneAnim = phoneAnim, row > -1 else {
      return nil
    }
    
    var animKey: AnimKey?
    if selectedSection == "Prep" && row < phoneAnim.prepAnimation.count {
      animKey = phoneAnim.prepAnimation[row]
    } else if selectedSection == "Sec" && row < phoneAnim.secAnimation.count {
      animKey = phoneAnim.secAnimation[row]
    } else if selectedSection == "Art" && row < phoneAnim.artAnimation.count {
      animKey = phoneAnim.artAnimation[row]
    }
    return animKey
  }
  
  func insertAnimKey(key: AnimKey, at row: Int) {
    guard let phoneAnim = phoneAnim else {
      return
    }
    
    if selectedSection == "Prep" {
      phoneAnim.prepAnimation.insert(key, at: row)
    } else if selectedSection == "Sec" {
      phoneAnim.secAnimation.insert(key, at: row)
    } else if selectedSection == "Art" {
      phoneAnim.artAnimation.insert(key, at: row)
    }
    updateAnimKeyMap()
  }
  
  func deleteAnimKey(forRow row: Int) {
    guard let phoneAnim = phoneAnim else {
      return
    }
    
    if selectedSection == "Prep" {
      phoneAnim.prepAnimation.remove(at: row)
    } else if selectedSection == "Sec" {
      phoneAnim.secAnimation.remove(at: row)
    } else if selectedSection == "Art" {
      phoneAnim.artAnimation.remove(at: row)
    }
    updateAnimKeyMap()
  }
  
  func switchAnimKey(forRow row: Int) {
    guard let phoneAnim = phoneAnim else {
      return
    }
    
    if selectedSection == "Prep" {
      let animKey = phoneAnim.prepAnimation.remove(at: row)
      phoneAnim.secAnimation.append(animKey)
    } else if selectedSection == "Sec" {
      let animKey = phoneAnim.secAnimation.remove(at: row)
      phoneAnim.prepAnimation.append(animKey)
    }
    
    updateAnimKeyMap()
  }
  
  // MARK: Action functions
  
  @IBAction func ipa(_ sender: NSButton) {
    if let popover = self.ipaPopover {
      if popover.isShown {
        popover.performClose(self)
      } else {
        popover.show(relativeTo: ipaTextField!.bounds, of: ipaTextField!, preferredEdge: .maxY)
      }
    }
  }
  
  @IBAction func save(_ sender: NSButton) {
    table?.abortEditing()
    let panel = NSSavePanel()
    panel.canCreateDirectories = true
    panel.allowedFileTypes = ["xml"]
    panel.beginSheetModal(for: self.window!) { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        if let url = panel.url, let animFactory = self.animFactory {
          guard let root = animFactory.encodeXML(withKey: "Animation") as? XMLElement else {
            return
          }
          let document = XMLDocument(rootElement: root)
          document.characterEncoding = "utf8"
          document.version = "1.0"
          document.isStandalone = true
          document.documentContentKind = XMLDocument.ContentKind.xml
          let xmlData: Data = document.xmlData
          do {
            try xmlData.write(to: url)
          } catch {
            let alert = NSAlert()
            alert.messageText = error.localizedDescription
            alert.runModal()
          }
        }
      }
    }
  }
  
  @IBAction func add(_ sender: NSButton) {
    guard let table = table else {
      return
    }
    table.abortEditing()
    let newAnimKey = AnimKey()
    newAnimKey.part = "head"
    insertAnimKey(key: newAnimKey, at: numberOfRows(in: table))
    table.reloadData()
  }
  
  @IBAction func delete(_ sender: NSButton) {
    guard let row = table?.selectedRow, row > -1 else {
      return
    }
    
    table?.abortEditing()
    deleteAnimKey(forRow: row)
    table?.reloadData()
  }
  
  @IBAction func switchPrepSec(_ sender: NSButton) {
    guard let row = table?.selectedRow, row > -1 else {
      return
    }
    
    switchAnimKey(forRow: row)
    table?.reloadData()
  }
  
  @IBAction func valueChange(_ sender: NSTextField) {
    guard let table = table else {
      return
    }
    
    let row = table.row(for: sender.superview!)
    
    guard let key = getAnimKey(forRow: row) else {
      return
    }
    
    let column = table.column(for: sender.superview!)
    let columnTitle = table.tableColumns[column].title
    
    switch columnTitle {
    case "Part": 
      key.part = sender.stringValue
      updateAnimKeyMap()
    case "Target": 
      key.target = sender.stringValue
      updateAnimKeyMap()
    case "min": key.minValue = sender.floatValue
    case "max": key.maxValue = sender.floatValue
    case "repeat": key.repeat_min = Int(sender.intValue)
    default: break
    }
    updateHead()
  }
  
  @IBAction func clear(_ sender: NSButton) {
    insertIPA(" ")
  }
  
  // MARK: IPA Symbols delegate function
  
  func insertIPA(_ ipa: String) {
    self.ipaSymbol = ipa
    ipaPopover?.performClose(self)
  }
  
  // MARK: Table View Data Source
  func numberOfRows(in tableView: NSTableView) -> Int {
    if let phoneAnim = self.phoneAnim {
      switch selectedSection {
      case "Prep": return phoneAnim.prepAnimation.count
      case "Sec": return phoneAnim.secAnimation.count
      case "Art": return phoneAnim.artAnimation.count
      default: break
      }
    }
    return 0
  }
  
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    guard let key = getAnimKey(forRow: row) else {
      return nil
    }
    
    switch tableColumn!.title {
    case "Part": return key.part
    case "Target": return key.target
    case "min": return key.minValue
    case "max": return key.maxValue
    case "repeat": return key.repeat_min
    default: return nil
    }
  }
  
  // MARK: Table View Delegate
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let tableColumn = tableColumn else {
      return nil
    }
    
    guard let key = getAnimKey(forRow: row) else {
      return nil
    }
    
    let viewID = tableColumn.title + "ViewID"
    if let columnView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: viewID), owner: self) {
      if let textView = columnView.subviews[0] as? NSTextField {
        textView.target = self
        textView.action = #selector(valueChange(_:))
        switch tableColumn.title {
        case "Part": textView.stringValue = key.part
        case "Target": textView.stringValue = key.target
        case "min": textView.floatValue = key.minValue
        case "max": textView.floatValue = key.maxValue
        case "repeat": textView.intValue = Int32(key.repeat_min)
        default: break
        }
      }
      return columnView
    }
    return nil
  }
}

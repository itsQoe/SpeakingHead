//
//  PerspectiveViewItem.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 14.12.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class PerspectiveViewItem: NSCollectionViewItem {
  
  @IBOutlet weak var imageButton: NSButton?
  @IBOutlet weak var saveButton: NSButton?
  @IBOutlet weak var deleteButton: NSButton?
  @IBOutlet weak var shortcutLabel: NSTextField?
  @IBOutlet weak var replaceButton: NSButton?
  
  var hideControls: Bool = false {
    didSet {
      saveButton?.isHidden = hideControls
      deleteButton?.isHidden = hideControls
      replaceButton?.isHidden = hideControls
      textField?.isEditable = !hideControls
      textField?.isBezeled = !hideControls
    }
  }
  
  weak var perspective: SHPerspectiveData?
  weak var perspectiveController: PerspectiveCollectionViewController?
  
  override func viewDidLoad() {
    saveButton?.isHidden = true
    deleteButton?.isHidden = true
    replaceButton?.isHidden = true
    textField?.isEditable = false
    textField?.isBezeled = false
  }
  
  func savePerspective(to url: URL) {
    if let perspective = self.perspective {
      NSKeyedArchiver.archiveRootObject(perspective, toFile: url.path)
    }
  }
  
  @IBAction func saveName(_ sender: NSTextField) {
    if let perspective = self.perspective {
      self.perspectiveController?.updateName(name: sender.stringValue, perspective: perspective)
    }
  }
  
  @IBAction func savePerspective(_ sender: NSButton) {
    let panel = NSSavePanel()
    panel.canCreateDirectories = true
    panel.allowedFileTypes = ["plist"]
    panel.begin() { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        if let url = panel.url {
          self.savePerspective(to: url)
        }
      }
    }
  }
  
  @IBAction func deletePerspective(_ sender: NSButton) {
    if let perspective = self.perspective {
      self.perspectiveController?.delete(perspective: perspective)
    }
  }
  
  @IBAction func replacePerspective(_ sender: NSButton) {
    guard let perspective = self.perspective else {
      return
    }
    
    if let index = perspectiveController?.perspectives?.perspectives.index(of: perspective),
      let new = perspectiveController?.animController?.headView?.perspectiveWithImage()
    {
      new.name = perspective.name
      self.perspectiveController?.replace(perspective: new, at: index)
    }
  }
}

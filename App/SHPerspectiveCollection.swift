//
//  SHPerspectiveCollection.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 29.03.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import AppKit

class SHPerspectiveCollection: NSObject {
  
  var perspectives = [SHPerspectiveData]() {
    didSet {
      saveToDefaults()
    }
  }
  
  var count: Int {
    return self.perspectives.count
  }
  
  var perspectivesMenu: NSMenu?
  
  func updateMenuItems() {
    if let menu = perspectivesMenu {
      for i in 0 ..< menu.items.count {
        if i < perspectives.count {
          if let name = perspectives[i].name, name != "" {
            menu.items[i].title = name
          } else {
            menu.items[i].title = "Custom"
          }
          menu.items[i].isEnabled = true
        } else {
          menu.items[i].title = "empty"
          menu.items[i].isEnabled = false
        }
      }
    }
  }
  
  func loadPerspectiveData() {  
    // Custom    
    if let data = UserDefaults.standard.data(forKey: custom_perspectives_key) {
      if let custom = NSKeyedUnarchiver.unarchiveObject(with: data) as? [SHPerspectiveData] {
        perspectives = custom
      }
    }
  }
  
  func saveToDefaults() {
    let defaults = UserDefaults.standard
    let perspectivesData = NSKeyedArchiver.archivedData(withRootObject: self.perspectives)
    defaults.set(perspectivesData, forKey: custom_perspectives_key)
  }

}

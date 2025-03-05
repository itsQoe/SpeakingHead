//
//  SettingsWindowController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 30.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class SettingsWindowController: NSWindowController {
  
  @IBOutlet weak var preferenceController: PreferenceController?
  
  override var windowNibName: NSNib.Name? {
    return NSNib.Name("SettingsWindowController")
  }
  
  @IBAction func resetPreferenceValue(_ sender: PreferenceResetButton) {
    if let key = sender.defaultKey {
      UserDefaults.standard.removeObject(forKey: key)
    }
  }
  
}

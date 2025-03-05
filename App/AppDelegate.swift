//
//  AppDelegate.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 07.09.15.
//  Copyright (c) 2015 Uli Held. All rights reserved.
//

import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  @IBOutlet weak var window: NSWindow!
  
  let helpPageURL: URL? = URL(string: "https://www.speakinghead.com/help")
  
  var userDefaultsManager: UserDefaultsManager?
  var mainWindowController: MainWindowController?
  var settingsWindowController: SettingsWindowController?

  func applicationDidFinishLaunching(_ aNotification: Notification) {    
    userDefaultsManager = UserDefaultsManager()
    
    let mainWindowController = MainWindowController()
    mainWindowController.showWindow(self)
    self.mainWindowController = mainWindowController
    self.settingsWindowController = SettingsWindowController()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  @IBAction func onPreferences(_ sender: NSMenuItem) {
    self.settingsWindowController?.showWindow(self)
    self.settingsWindowController?.preferenceController?.activate(index: sender.tag)
  }
  
  @IBAction func onHelpPage(_ sender: NSMenuItem) {
    if let url = helpPageURL, NSWorkspace.shared.open(url) {
      return
    }
    
    let alert = NSAlert()
    alert.messageText = "Unable to open help page"
    alert.informativeText = "URL: " + (helpPageURL?.absoluteString ?? "not found")
    alert.runModal()

  }
}


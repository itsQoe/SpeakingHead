//
//  PreferenceController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 01.12.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class PreferenceController: NSViewController {
  
  @IBOutlet weak var tabView: NSTabView?
  @IBOutlet weak var toolBar: NSToolbar?
  
  override func viewDidLoad() {
    if let identifierStr = tabView?.selectedTabViewItem?.identifier as? String {
      toolBar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: identifierStr)
    }
  }
  
  @IBAction func onTab(_ sender: NSToolbarItem) {
    tabView?.selectTabViewItem(withIdentifier: sender.itemIdentifier)
  }
  
  @IBAction func onFont(_ sender: NSButton) {
    NSFontPanel.shared.makeKeyAndOrderFront(sender)
  }
  
  func activate(index: Int) {
    if let toolBarItem = toolBar?.items[index] {
      toolBar?.selectedItemIdentifier = toolBarItem.itemIdentifier
      tabView?.selectTabViewItem(withIdentifier: toolBarItem.itemIdentifier)
    }
  }
}

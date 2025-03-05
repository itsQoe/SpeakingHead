//
//  MorphWindowController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 08.04.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Cocoa
import SceneKit

class MorphWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {

  var morphTargets: [String]?
  var scnNode: SCNNode?
  
  @IBOutlet weak var tableView: NSTableView!
  
  override var windowNibName: NSNib.Name? {
    return NSNib.Name("MorphWindowController")
  }
  
  override func windowDidLoad() {
    super.windowDidLoad()    
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return morphTargets?.count ?? 0
  }
  
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    if tableColumn?.title == "Target" {
      return morphTargets?[row] ?? ""
    } else if tableColumn?.title == "Value" {
      return scnNode?.morpher?.weight(forTargetAt: row) ?? 0.0
    } else {
      return nil
    }
  }
    
  @IBAction func onEndEditing(_ sender: NSControl) {
    let rowNumber = tableView.row(for: sender.superview!)
    if rowNumber != -1 {
      let value = sender.floatValue
      scnNode!.morpher?.setWeight(CGFloat(value), forTargetAt: rowNumber)

    }
  }
  
}

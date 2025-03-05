//
//  IPAPopoverController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 24.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class IPAPopoverController: NSViewController, NSTableViewDelegate {
  
  @IBOutlet weak var consonantTable: NSTableView?
  @IBOutlet weak var vowelTable: NSTableView?
  @IBOutlet weak var textView: IPATextView?
  @IBOutlet weak var userDefaultsController: NSUserDefaultsController?
  @IBOutlet weak var window: NSWindow?
  
  var consonantData: ConsonantTableData = ConsonantTableData()
  var vowelData: VowelTableData = VowelTableData()
    
  override func viewDidLoad() {
    consonantTable?.dataSource = consonantData
    vowelTable?.dataSource = vowelData
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    if let dataObject = tableView.dataSource?.tableView?(tableView, objectValueFor: tableColumn, row: row) {
      if let ipaSymbols = dataObject as? IPASymbols {
        if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LeftRightDataID"), owner: nil) as? NSTableCellView {
          if let leftLabel = cellView.subviews[0] as? NSTextField {
            leftLabel.target = self
            leftLabel.action = #selector(onClick)
            if ipaSymbols.left != "" {
              leftLabel.stringValue = ipaSymbols.left
              leftLabel.bind(NSBindingName(rawValue: "mouseOverColor"), 
                             to: userDefaultsController!, 
                             withKeyPath: "values."+symbol_highlighting_color_key, 
                             options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
            } else {
              leftLabel.isHidden = true  
            }
            
          }
          if let rightLabel = cellView.subviews[1] as? NSTextField {
            rightLabel.target = self
            rightLabel.action = #selector(onClick)
            if ipaSymbols.right != "" {
              rightLabel.stringValue = ipaSymbols.right
              rightLabel.bind(NSBindingName(rawValue: "mouseOverColor"), 
                             to: userDefaultsController!, 
                             withKeyPath: "values."+symbol_highlighting_color_key, 
                             options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
            } else {
              rightLabel.isHidden = true
            }
          }
          return cellView
        }
      } else if let rowName = dataObject as? String {
        if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RowNameID"), owner: nil) as? NSTableCellView {
          cellView.textField?.stringValue = rowName
          return cellView
        }
      }
    }
    return nil
  }
    
  @IBAction func onClick(_ sender: NSButton) {
    let ipaStr = sender.stringValue
    textView?.insertText(ipaStr, replacementRange: NSRange())
    window?.makeFirstResponder(textView!)
  }  
}

//
//  ImageExportController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 09.12.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class ImageExportController: NSViewController {
  
  @IBOutlet weak var widthTextField: NSTextField?
  @IBOutlet weak var heightTextField: NSTextField?
  @IBOutlet weak var templatePopup: NSPopUpButton?
  @IBOutlet weak var userDefaultsController: NSUserDefaultsController?
  
  var exportSize: CGSize? {
    get {
      if let width = widthTextField?.intValue, let height = heightTextField?.intValue {
        return CGSize(width: CGFloat(width), height: CGFloat(height))
      } else {
        return nil
      }
    }
  }
  
  @objc dynamic var exportWidth: NSNumber? {
    didSet {
      self.onResolutionChange(self)
    }
  }
  
  @objc dynamic var exportHeight: NSNumber? {
    didSet {
      self.onResolutionChange(self)
    }
  }
  
  override var nibName: NSNib.Name? {
    return NSNib.Name("ImageExportView")
  }
  
  let customString: String = "Custom Resolution"
  var resolutionTemplates: [String: CGSize] = [
    "256 * 256 (1:1)": CGSize(width: 256.0, height: 256.0),
    "800 * 600 (4:3)": CGSize(width: 800.0, height: 600.0),
    "1024 * 800 (4:3)": CGSize(width: 1024.0, height: 800.0),
    "1280 * 720 (16:9)": CGSize(width: 1280.0, height: 720.0)
  ]
  
  override func viewDidLoad() {
    
    if let numberFormatter = widthTextField?.formatter as? NumberFormatter {
      numberFormatter.generatesDecimalNumbers = false
    }
    
    if let numberFormatter = heightTextField?.formatter as? NumberFormatter {
      numberFormatter.generatesDecimalNumbers = false
    }
    
    templatePopup?.removeAllItems()
    templatePopup?.addItem(withTitle: customString)
    templatePopup?.menu?.addItem(NSMenuItem.separator())
    templatePopup?.addItems(withTitles: Array(resolutionTemplates.keys))
    
    self.bind(NSBindingName(rawValue: "exportWidth"), 
              to: userDefaultsController!, 
              withKeyPath: "values."+image_export_width_key, 
              options: nil)
    
    self.bind(NSBindingName(rawValue: "exportHeight"), 
              to: userDefaultsController!, 
              withKeyPath: "values."+image_export_height_key, 
              options: nil)
    
  }
  
  @IBAction func onTemplate(_ sender: NSPopUpButton) {
    if let itemStr = sender.selectedItem?.title, let size = resolutionTemplates[itemStr] {
      widthTextField?.intValue = Int32(size.width)
      heightTextField?.intValue = Int32(size.height)
    }
  }
  
  @IBAction func onResolutionChange(_ sender: Any) {
    if let width = exportWidth?.intValue, 
      let height = exportHeight?.intValue {
      let newSize = CGSize(width: width, height: height)
      for (key, value) in resolutionTemplates {
        if value == newSize {
          templatePopup?.selectItem(withTitle: key)
          return
        }
      }
      templatePopup?.selectItem(withTitle: customString)
    }
  }
}

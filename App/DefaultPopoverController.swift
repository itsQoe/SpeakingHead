//
//  DefaultPopoverController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 30.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class DefaultPopoverController: NSViewController, IPASymbolViewDelegate {
  
  @IBOutlet weak var ipaTextView: IPATextView?
  @IBOutlet weak var userDefaultsController: NSUserDefaultsController?
  
  var defaultSymbol: IPASymbolView?
  var defaultPhone = Phone() {
    didSet {
      defaultSymbol?.phone = defaultPhone
      defaultSymbol?.updateView()
    }
  }
  
  override func viewDidLoad() {
    let origin = CGPoint(x: 8, y: 8)
    defaultSymbol = IPASymbolView(frame: CGRect(origin: origin, size: CGSize.zero),
                                  phone: defaultPhone)
    defaultSymbol?.max_duration = 0.5
    defaultSymbol?.autoHideControls = false
    defaultSymbol?.showControls = true
    defaultSymbol?.delegate = self
    defaultSymbol?.infoPanel = SHInfoPanel()
    self.view.addSubview(defaultSymbol!)
  }
    
  func phoneDidChange(sender: IPASymbolView) {
    if let defaults = self.userDefaultsController?.defaults {
      let defaultPhoneData = NSKeyedArchiver.archivedData(withRootObject: sender.phone!)
      defaults.set(defaultPhoneData, forKey: ipa_default_key)
    }
  }
  
}

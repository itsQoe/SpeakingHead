//
//  SHMessageView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 26.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

class SHMessageView: NSTextField {
  
  override func mouseUp(with event: NSEvent) {
    self.isHidden = true
  }
}

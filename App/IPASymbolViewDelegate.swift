//
//  IPASymbolViewDelegate.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 16.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Foundation

@objc protocol IPASymbolViewDelegate {
  
  @objc func phoneDidChange(sender: IPASymbolView)
  
  @objc optional func phoneDidResize(sender: IPASymbolView)
}

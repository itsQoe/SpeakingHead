//
//  IPATextViewDelegate.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 16.11.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

@objc protocol IPATextViewDelegate {
  
  @objc func textDidChange(sender: IPATextView)
  
  @objc optional func textDidResize(sender: IPATextView)
  
  @objc func updatePosition(at pos: CGFloat)
  
  @objc func errorMessage(sender: AnyObject, message: String)
  
  @objc func requestPopover(_ sender: NSView)
}

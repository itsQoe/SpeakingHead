//
//  PhoneAnimation.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 02.04.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Foundation

fileprivate let symbol_key = "symbol"
fileprivate let mode_key = "mode"
fileprivate let prep_animation_key = "prep_animation"
fileprivate let sec_animation_key = "sec_animation"
fileprivate let art_animation_key = "art_animation"

class PhoneAnimation: NSObject, NSCoding, XMLCoding {
  
  var symbol: String = ""
  var mode: String = ""
  var prepAnimation: [AnimKey] = [AnimKey]()
  var secAnimation: [AnimKey] = [AnimKey]()
  var artAnimation: [AnimKey] = [AnimKey]()
  
  override init() {
    super.init()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init()
    if let symbol = aDecoder.decodeObject(forKey: symbol_key) as? String {
      self.symbol = symbol
    }
    if let mode = aDecoder.decodeObject(forKey: mode_key) as? String {
      self.mode = mode
    }
    if let prepAnimation = aDecoder.decodeObject(forKey: prep_animation_key) as? [AnimKey] {
      self.prepAnimation = prepAnimation
    }
    if let secAnimation = aDecoder.decodeObject(forKey: sec_animation_key) as? [AnimKey] {
      self.secAnimation = secAnimation
    }
    if let artAnimation = aDecoder.decodeObject(forKey: art_animation_key) as? [AnimKey] {
      self.artAnimation = artAnimation
    }
  }
  
  required init?(with node: XMLNode) throws {
    super.init()
    
    guard let node = node as? XMLElement else {
      throw IPATextError(kind: .xmlParsingError)
    }
    
    if let symbolStr = node.attribute(forName: symbol_key)?.stringValue {
      self.symbol = symbolStr
    }
    
    if let modeStr = node.attribute(forName: mode_key)?.stringValue {
      self.mode = modeStr
    }
    // Animation Arrays
    if let prepAnimNode = node.elements(forName: prep_animation_key).first {
      if let array = try Array<AnimKey>(with: prepAnimNode) {
        self.prepAnimation = array
      }
    }
    
    if let secAnimNode = node.elements(forName: sec_animation_key).first {
      if let array = try Array<AnimKey>(with: secAnimNode) {
        self.secAnimation = array
      }
    }
    
    if let artAnimNode = node.elements(forName: art_animation_key).first {
      if let array = try Array<AnimKey>(with: artAnimNode) {
        self.artAnimation = array
      }
    }
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(symbol, forKey: symbol_key)
    aCoder.encode(mode, forKey: mode_key)
    aCoder.encode(prepAnimation, forKey: prep_animation_key)
    aCoder.encode(secAnimation, forKey: sec_animation_key)
    aCoder.encode(artAnimation, forKey: art_animation_key)
  }
  
  func encodeXML(withKey key: String) -> XMLNode {
    let root = XMLElement(name: key)
    if let attr: XMLNode = XMLNode.attribute(withName: symbol_key, stringValue: self.symbol) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: mode_key, stringValue: self.mode) as? XMLNode {
      root.addAttribute(attr)
    }
    root.addChild(prepAnimation.encodeXML(withKey: prep_animation_key))
    root.addChild(secAnimation.encodeXML(withKey: sec_animation_key))
    root.addChild(artAnimation.encodeXML(withKey: art_animation_key))
    return root
  }
  
  func copyWithZone(_: NSZone?) -> AnyObject {
    let newPhone = PhoneAnimation()
    newPhone.symbol = symbol
    newPhone.mode = mode
    newPhone.prepAnimation = prepAnimation
    newPhone.secAnimation = secAnimation
    newPhone.artAnimation = artAnimation
    return newPhone
  }
}

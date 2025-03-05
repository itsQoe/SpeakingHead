//
//  Phone.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 03.02.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Foundation

fileprivate let symbol_key = "symbol"
fileprivate let mode_key = "mode"
fileprivate let prep_duration_key = "prep_duration"
fileprivate let sec_duration_key = "sec_duration"
fileprivate let art_duration_key = "art_duration"
fileprivate let articulation_key = "articulation"

class Phone: NSObject, NSCoding, XMLCoding {
  
  var symbol: String = ""
  var mode: String = ""
  
  var prep_duration: Float = 0.1
  var sec_duration: Float = 0.1
  var art_duration: Float = 0.1
  
  var articulation: Float = 0.5
  
  var duration: Float {
    return prep_duration + art_duration
  }
  
  var ipaString: String {
    return symbol
  }
  
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
    self.prep_duration = aDecoder.decodeFloat(forKey: prep_duration_key)
    self.sec_duration = aDecoder.decodeFloat(forKey: sec_duration_key)
    self.art_duration = aDecoder.decodeFloat(forKey: art_duration_key)
    self.articulation = aDecoder.decodeFloat(forKey: articulation_key)
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
    
    if let prepDurationStr = node.attribute(forName: prep_duration_key)?.stringValue {
      if let value = Float(prepDurationStr) {
        self.prep_duration = value
      }
    }
    
    if let secDurationStr = node.attribute(forName: sec_duration_key)?.stringValue {
      if let value = Float(secDurationStr) {
        self.sec_duration = value
      }
    }
    if let artDurationStr = node.attribute(forName: art_duration_key)?.stringValue {
      if let value = Float(artDurationStr) {
        self.art_duration = value
      }
    }
    if let articulationStr = node.attribute(forName: articulation_key)?.stringValue {
      if let value = Float(articulationStr) {
        self.articulation = value
      }
    }
  }
  
  override var description : String {
    return NSString(format: "Symbol: %@; Durations: prep=%f sec=%f art=%f Articulation: factor=%f", 
                    symbol, prep_duration, sec_duration, art_duration, articulation) as String
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(symbol, forKey: symbol_key)
    aCoder.encode(mode, forKey: mode_key)
    aCoder.encode(prep_duration, forKey: prep_duration_key)
    aCoder.encode(sec_duration, forKey: sec_duration_key)
    aCoder.encode(art_duration, forKey: art_duration_key)
    aCoder.encode(articulation, forKey: articulation_key)
  }
  
  func encodeXML(withKey key: String) -> XMLNode {
    let root = XMLElement(name: key)
    if let attr: XMLNode = XMLNode.attribute(withName: symbol_key, stringValue: self.symbol) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: mode_key, stringValue: self.mode) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: prep_duration_key, stringValue: String(self.prep_duration)) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: sec_duration_key, stringValue: String(self.sec_duration)) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: art_duration_key, stringValue: String(self.art_duration)) as? XMLNode {
      root.addAttribute(attr)
    }    
    return root
  }
  
  func getArticulationValue(_ min: Float, max: Float) -> Float {
    return min + (max-min)*articulation
  }
  
  @objc func copyWithZone(_: NSZone?) -> AnyObject {
    let newPhone = Phone()
    newPhone.symbol = symbol
    newPhone.mode = mode
    newPhone.prep_duration = prep_duration
    newPhone.art_duration = art_duration
    newPhone.articulation = articulation
    return newPhone
  }
}

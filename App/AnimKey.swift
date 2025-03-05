//
//  AnimKey.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 04.04.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Foundation

fileprivate let part_key = "part"
fileprivate let target_key = "target"
fileprivate let min_value_key = "min_value"
fileprivate let max_value_key = "max_value"
fileprivate let repeat_min_key = "repeat_min"

class AnimKey: NSObject, NSCoding, XMLCoding {
  var part: String = ""
  var target: String = ""
  var minValue: Float = 0.0
  var maxValue: Float = 0.0
  var repeat_min: Int = 0
  
  override init() {
    super.init()
  }
  
  convenience init(part: String, target: String, min: Float, max: Float, rep: Int) {
    self.init()
    self.part = part
    self.target = target
    self.minValue = min
    self.maxValue = max
    self.repeat_min = rep
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init()
    if let part = aDecoder.decodeObject(forKey: part_key) as? String {
      self.part = part
    }
    if let target = aDecoder.decodeObject(forKey: target_key) as? String {
      self.target = target
    }
    
    minValue = aDecoder.decodeFloat(forKey: min_value_key)
    maxValue = aDecoder.decodeFloat(forKey: max_value_key)
    repeat_min = Int(aDecoder.decodeInt32(forKey: repeat_min_key))
  }
  
  required init?(with node: XMLNode) throws {
    guard let node = node as? XMLElement else {
      throw IPATextError(kind: .xmlParsingError)
    }
    
    if let str = node.attribute(forName: part_key)?.stringValue {
      self.part = str
    }
    if let str = node.attribute(forName: target_key)?.stringValue {
      self.target = str
    }
    
    if let str = node.attribute(forName: min_value_key)?.stringValue {
      if let value = Float(str) {
        self.minValue = value
      }
    }
    
    if let str = node.attribute(forName: max_value_key)?.stringValue {
      if let value = Float(str) {
        self.maxValue = value
      }
    }
    
    if let str = node.attribute(forName: repeat_min_key)?.stringValue {
      if let value = Int(str) {
        self.repeat_min = value
      }
    }
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(part, forKey: part_key)
    aCoder.encode(target, forKey: target_key)
    aCoder.encode(minValue, forKey: min_value_key)
    aCoder.encode(maxValue, forKey: max_value_key)
    aCoder.encode(repeat_min, forKey: repeat_min_key)
  }
  
  func encodeXML(withKey key: String) -> XMLNode {
    let root = XMLElement(name: key)
    if let attr: XMLNode = XMLNode.attribute(withName: part_key, stringValue: self.part) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: target_key, stringValue: self.target) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: min_value_key, stringValue: String(self.minValue)) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: max_value_key, stringValue: String(self.maxValue)) as? XMLNode {
      root.addAttribute(attr)
    }
    if let attr: XMLNode = XMLNode.attribute(withName: repeat_min_key, stringValue: String(self.repeat_min)) as? XMLNode {
      root.addAttribute(attr)
    }    
    return root
  }
  
  func isInRange(_ value: Float) -> Bool {
    return value >= minValue && value <= maxValue
  }
}

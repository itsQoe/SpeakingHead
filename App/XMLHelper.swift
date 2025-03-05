//
//  DictionaryXMLExtension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 12.04.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Foundation

class XMLHelper {
  class func decodeDict<T: XMLCoding>(node: XMLNode) throws -> [String: T] {
    var newDict = [String: T]() 
    guard let children = node.children else {
      return newDict
    }
    for child in children {
      if let xmlElement = child as? XMLElement {
        if let k = xmlElement.attribute(forName: "key")?.stringValue,
          let valueNode = xmlElement.elements(forName: "value").first,
          let v = try T(with: valueNode)
        {
          newDict[k] = v
        }
      }
    }
    return newDict
  }
  
  class func decodeStringDict<T: LosslessStringConvertible>(node: XMLNode) -> [String: T] {
    var newDict = [String: T]() 
    guard let children = node.children else {
      return newDict
    }
    for child in children {
      if let xmlElement = child as? XMLElement {
        if let key = xmlElement.attribute(forName: "key")?.stringValue,
          let str = xmlElement.attribute(forName: "value")?.stringValue
        {
          newDict[key] = T(str)
        }
      }
    }
    return newDict
  }
  
  class func encodeDict(dict: [String: XMLCoding], key: String) -> XMLNode {
    let root = XMLElement(name: key)
    for (k, v) in dict {
      let element = XMLElement(name: "element")
      if let attr: XMLNode = XMLNode.attribute(withName: "key", stringValue: k) as? XMLNode {
        element.addAttribute(attr)
      }
      if let valueNode = v.encodeXML(withKey: "value") as? XMLElement {
        element.addChild(valueNode)
      }
      root.addChild(element)
    }
    return root
  }
  
  class func encodeStringDict(dict: [String: CustomStringConvertible], key: String) -> XMLNode {
    let root = XMLElement(name: key)
    for (k, v) in dict {
      let element = XMLElement(name: "element")
      if let attr: XMLNode = XMLNode.attribute(withName: "key", stringValue: k) as? XMLNode {
        element.addAttribute(attr)
      }
      if let attr: XMLNode = XMLNode.attribute(withName: "value", stringValue: v.description) as? XMLNode {
        element.addAttribute(attr)
      }
      
      root.addChild(element)
    }
    return root
  }
}

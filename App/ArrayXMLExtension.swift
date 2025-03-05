//
//  ArrayXMLExtension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 03.02.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Foundation

extension Array where Element : XMLCoding {
  
  init?(with node: XMLElement) throws {
    self.init()
    guard let children = node.children else {
      return
    }
    
    for child in children {
      if let xmlElement = child as? XMLElement {
        if let e = try Element(with: xmlElement) {
          self.append(e)
        }
      }
    }
  }
  
  func encodeXML(withKey key: String) -> XMLElement {
    let root = XMLElement(name: key)
    for e in self {
      root.addChild(e.encodeXML(withKey: "element"))
    }
    return root
  }
}

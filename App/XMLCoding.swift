//
//  XMLCoding.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 03.02.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Foundation

protocol XMLCoding {
  
  init?(with node: XMLNode) throws
  
  func encodeXML(withKey key: String) -> XMLNode
}

//
//  IPAText.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 02.04.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Cocoa

fileprivate let version_key = "version"
fileprivate let text_url_key = "text_url"
fileprivate let audio_url_key = "audio_url"
fileprivate let default_phone_key = "default_phone"
fileprivate let phone_array_key = "phone_array"

class IPAText: NSObject, NSCoding, XMLCoding {
  var version: String = "1.0"
  var audioURL: URL?
  var defaultPhone: Phone?
  var phoneArray: [Phone]?
  
  override init() {
    super.init()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init()
    if let url = aDecoder.decodeObject(forKey: audio_url_key) as? URL {
      self.audioURL = url
    }
    if let phone = aDecoder.decodeObject(forKey: default_phone_key) as? Phone {
      self.defaultPhone = phone
    }
    if let array = aDecoder.decodeObject(forKey: phone_array_key) as? [Phone] {
      self.phoneArray = array
    }
  }
  
  required init?(with node: XMLNode) throws {
    guard let node = node as? XMLElement, node.name == "IPAText" else {
      throw IPATextError(kind: .xmlParsingError)
    }
    
    if let versionStr = node.attribute(forName: version_key)?.stringValue {
      self.version = versionStr
    } else {
      throw IPATextError(kind: .versionError)
    }
    
    if let urlStr = node.attribute(forName: audio_url_key)?.stringValue {
      self.audioURL = URL(fileURLWithPath: urlStr)
    }
    
    if let xml = node.elements(forName: default_phone_key).first,
      let phone = try Phone(with: xml)
    {
      self.defaultPhone = phone
    }
    
    if let xml = node.elements(forName: phone_array_key).first,
      let array = try Array<Phone>(with: xml)
    {
      self.phoneArray = array
    }
  }
  
  required init?(pasteboardPropertyList: Any, ofType: String) {
    
  }
  
  
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(audioURL, forKey: audio_url_key)
    aCoder.encode(defaultPhone, forKey: default_phone_key)
    aCoder.encode(phoneArray, forKey: phone_array_key)
  }
  
  func encodeXML(withKey key: String) -> XMLNode {
    let root = XMLElement(name: key)
    
    // Version
    if let attr: XMLNode = XMLNode.attribute(withName: version_key, stringValue: self.version) as? XMLNode {
      root.addAttribute(attr)
    }
    
    if let urlString = self.audioURL?.path {
      if let attr: XMLNode = XMLNode.attribute(withName: audio_url_key, stringValue: urlString) as? XMLNode {
        root.addAttribute(attr)
      }
    }
    if let defaultPhone = self.defaultPhone {
      root.addChild(defaultPhone.encodeXML(withKey: default_phone_key))
    }
    if let phoneArray = self.phoneArray {
      root.addChild(phoneArray.encodeXML(withKey: phone_array_key))
    }
    return root
  }
}

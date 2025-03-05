//
//  NSObjectExtension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 12.08.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Foundation

extension NSObject {
  
  //
  // Retrieves an array of property names found on the current object
  // using Objective-C runtime functions for introspection:
  // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
  //
  func propertyNames() -> Array<String> {
    var results: Array<String> = [];
    
    // retrieve the properties via the class_copyPropertyList function
    var count: UInt32 = 0;
    let myClass: AnyClass = self.classForCoder;
    let properties = class_copyPropertyList(myClass, &count);
    
    // iterate each objc_property_t struct
    for i: UInt32 in 0 ..< count {
      let property = properties?[Int(i)];
      
      // retrieve the property name by calling property_getName function
      let cname = property_getName(property!);
      
      // covert the c string into a Swift string
      let name = String(cString: cname);
      results.append(name);
    }
    
    // release objc_property_t structs
    free(properties);
    
    return results;
  }
  
}

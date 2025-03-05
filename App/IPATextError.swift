//
//  IPATextError.swift
//  SpeakingHead
//
//  Created by Uli Held on 15.05.17.
//  Copyright © 2017 SpeakingOf UG (haftungsbeschränkt). All rights reserved.
//

import Foundation

class IPATextError: Error {
  enum ErrorKind {
    case xmlParsingError
    case versionError
  }
  
  let kind: ErrorKind
  
  var localizedDescription: String {
    return "Could not read XML file!"
  }
  
  init(kind: ErrorKind) {
    self.kind = kind
  }
}

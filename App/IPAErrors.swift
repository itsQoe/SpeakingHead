//
//  IPAErrors.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 15.07.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Foundation

enum IPAError: Error {
  case notAnIPACharacter(char: String)
}

//
//  ClosedRangeExtension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 27.01.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Foundation

extension ClosedRange {
  func clamp(_ value : Bound) -> Bound {
    return self.lowerBound > value ? self.lowerBound
      : self.upperBound < value ? self.upperBound
      : value
  }
}

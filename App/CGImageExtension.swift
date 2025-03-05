//
//  NSImageExtension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 10.12.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

extension CGImage {
  
  func saveAsPNG(to url: URL, compression: NSNumber) throws {
    let bitmapRep = NSBitmapImageRep(cgImage: self)
    if let pngData = bitmapRep.representation(using: .png, 
                                              properties: [NSBitmapImageRep.PropertyKey.compressionFactor: compression]) {
        try pngData.write(to: url, options: [.atomic])
    }
  }
  
}

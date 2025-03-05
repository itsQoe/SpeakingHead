//
//  HelperFunctions.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 08.09.15.
//  Copyright (c) 2015 Uli Held. All rights reserved.
//

import SceneKit

func GLKMatrixFromSCNMatrix(_ m: SCNMatrix4) -> GLKMatrix4 {
  return GLKMatrix4Make(
    Float(m.m11), Float(m.m12), Float(m.m13), Float(m.m14),
    Float(m.m21), Float(m.m22), Float(m.m23), Float(m.m24),
    Float(m.m31), Float(m.m32), Float(m.m33), Float(m.m34),
    Float(m.m41), Float(m.m42), Float(m.m43), Float(m.m44)
  )
}

extension CABasicAnimation {
  func toString() -> String {
    return NSString(format: "[keyPath=%@, autoreverses=%@, repeatCount=%f, duration=%f, beginTime=%@]", self.keyPath!, self.autoreverses ? "true" : "false", self.repeatCount, self.duration, self.beginTime.description) as String
  }
}

func getStringFromFile(_ name: String, type: String) -> String? {
  if let path = Bundle.main.path(forResource: name, ofType: type) {
    do {
      let content = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
      return content
    } catch _ as NSError {
      let alert = NSAlert()
      alert.messageText = "Unable to read \(path.debugDescription)"
      alert.runModal()
      return nil
    }
  } else {
    let alert = NSAlert()
    alert.messageText = "Resource named '\(name)' with type '\(type)' not found!"
    alert.runModal()
    return nil
  }
}

func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
  return min(max(value, lower), upper)
}

func invertColor(_ color: NSColor) -> NSColor? {
  if let rgbColor = color.usingColorSpaceName(NSColorSpaceName.calibratedRGB) {
    return NSColor(calibratedRed: 1.0 - rgbColor.redComponent,
                   green: 1.0 - rgbColor.greenComponent,
                   blue: 1.0 - rgbColor.blueComponent,
                   alpha: 1.0)    
  }
  return nil
}

func visibleColor(forBackgroundColor back: NSColor, forColor front: NSColor) -> NSColor? {
  if let front_rgb = front.usingColorSpaceName(NSColorSpaceName.calibratedRGB), 
    let back_rgb = back.usingColorSpaceName(NSColorSpaceName.calibratedRGB) 
  {
    let brightness: CGFloat = back_rgb.brightnessComponent >= 0.5 ? 0.0 : 1.0
    return NSColor(calibratedHue: front_rgb.hueComponent, 
                   saturation: front_rgb.saturationComponent, 
                   brightness: brightness, 
                   alpha: front_rgb.alphaComponent)
  }
  return nil
}

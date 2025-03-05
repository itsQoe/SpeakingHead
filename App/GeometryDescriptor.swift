//
//  GeometryDescriptor.swift
//  SceneKitTest
//
//  Created by Uli Held on 09.08.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import SceneKit

extension SCNGeometry {
  
  public func fullDescription() -> String {
    var str: String = "Geometry: \(name ?? "NONE") LoD count=\(levelsOfDetail?.count ?? 0) subdivision=\(subdivisionLevel)\n\n"
    str += "=== Geometry Sources ===\n"
    for source in self.sources {
      str += "Source: \(source.semantic)\n"
      str += "Vector Count: \(source.vectorCount)\n"
      str += "Bytes per Component: \(source.bytesPerComponent)\n"
      str += "Components per Vector: \(source.componentsPerVector)\n"
      str += "Float Components: \(source.usesFloatComponents)\n"
      str += "Data Offset: \(source.dataOffset)\n"
      str += "Data Stride: \(source.dataStride)\n"
      str += "Data Size: \(source.data.count)\n\n"
    }
    
    str += "=== Geometry Elements ===\n"
    for elem in self.elements {
      str += "Bytes per Index: \(elem.bytesPerIndex)\n"
      str += "Primitive Count: \(elem.primitiveCount)\n"
      str += "Primitive Type: \(getPrimitiveTypeString(elem.primitiveType))\n"
      str += "Data Size: \(elem.data.count)\n\n"
    }
    
    str += "=== Materials ===\n"
    for m in self.materials {
      str += "Name=\(m.name ?? "none")\n" 
      str += "shininess=\(m.shininess) fresnel=\(m.fresnelExponent)\n" 
      str += "transparancy=\(m.transparency) trans-mode=\(m.transparencyMode.rawValue)\n"
      str += "lighting=\(m.lightingModel) lit-per-pixel=\(m.isLitPerPixel)\n"
      str += "double-sided=\(m.isDoubleSided) cull-mode=\(m.cullMode)\n"
      str += "lock-AD=\(m.locksAmbientWithDiffuse)\n"
      str += "write-depth=\(m.writesToDepthBuffer) read-depth=\(m.readsFromDepthBuffer)\n"
      str += "Diffuse: contents=\(getMaterialPropertyContentName(m.diffuse.contents as AnyObject?)) intensity=\(m.diffuse.intensity)\n"
      str += "Ambient: contents=\(getMaterialPropertyContentName(m.ambient.contents as AnyObject?)) intensity=\(m.ambient.intensity)\n"
      str += "Specular: contents=\(getMaterialPropertyContentName(m.specular.contents as AnyObject?)) intensity=\(m.specular.intensity)\n"
      str += "Normal: contents=\(getMaterialPropertyContentName(m.normal.contents as AnyObject?)) intensity=\(m.normal.intensity)\n"
      str += "Reflective: contents=\(getMaterialPropertyContentName(m.reflective.contents as AnyObject?)) intensity=\(m.reflective.intensity)\n"
      str += "Emission: contents=\(getMaterialPropertyContentName(m.emission.contents as AnyObject?)) intensity=\(m.emission.intensity)\n"
      str += "Transparent: contents=\(getMaterialPropertyContentName(m.transparent.contents as AnyObject?)) intensity=\(m.transparent.intensity)\n"
      str += "Multiply: contents=\(getMaterialPropertyContentName(m.multiply.contents as AnyObject?)) intensity=\(m.multiply.intensity)\n"
      str += "AmbientOcclusion: contents=\(getMaterialPropertyContentName(m.ambientOcclusion.contents as AnyObject?)) intensity=\(m.ambientOcclusion.intensity)\n"
      str += "SelfIllumination: contents=\(getMaterialPropertyContentName(m.selfIllumination.contents as AnyObject?)) intensity=\(m.selfIllumination.intensity)\n"
      str += "\n"
    }
    
    return str
  }
  
  public func getPrimitiveTypeString(_ t: SCNGeometryPrimitiveType) -> String {
    var str: String = "none"
    switch t {
    case .line: str = "Line"
    case .point: str = "Point"
    case .triangles: str = "Triangles"
    case .triangleStrip: str = "TriangleStrip"
    case .polygon: str = "Polygon"
    }
    return str
  }
  
  public func getMaterialPropertyContentName(_ content: Any?) -> String {
    if let obj = content {
      if obj is NSColor {
        return "NSColor"
      }
//      if obj is CGColor {
//        return "CGColorRef"
//      }
      if obj is NSImage {
        return "NSImage"
      }
//      if obj is CGImage {
//        return "CGImageRef"
//      }
      if obj is NSString {
        return "NSString"
      }
      if obj is URL {
        return "NSURL"
      }
      if obj is NSArray {
        return "NSArray"
      }
      if obj is CALayer {
        return "CALayer"
      }
      if obj is MTLTexture {
        return "MTLTexture"
      }
      return "unknown"
    } else {
      return "NIL"
    }
    
  }
  
}

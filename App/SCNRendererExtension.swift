//
//  SCNRendererExtension.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 09.12.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//
//  Based on code from Wil Shipley http://stackoverflow.com/questions/23503472/cannot-create-a-screenshot-of-a-scnview


import SceneKit
import Accelerate
import CoreGraphics

public extension SCNRenderer {
  
  public func renderToImageSize(size: CGSize, floatComponents: Bool, atTime time: TimeInterval) -> CGImage? {
    
    var thumbnailCGImage: CGImage?
    
    let width = GLsizei(size.width), height = GLsizei(size.height)
    let samplesPerPixel = 4
    
    #if os(iOS)
      let oldGLContext = EAGLContext.currentContext()
      let glContext = unsafeBitCast(context, EAGLContext.self)
      
      EAGLContext.setCurrentContext(glContext)
      objc_sync_enter(glContext)
    #elseif os(OSX)
      let oldGLContext = CGLGetCurrentContext()
      let glContext = unsafeBitCast(context, to: CGLContextObj.self)
      
      CGLSetCurrentContext(glContext)
      CGLLockContext(glContext)
    #endif
    
    // set up the OpenGL buffers
    var thumbnailFramebuffer: GLuint = 0
    glGenFramebuffers(1, &thumbnailFramebuffer)
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), thumbnailFramebuffer)
    // checkGLErrors()
    
    var colorRenderbuffer: GLuint = 0
    glGenRenderbuffers(1, &colorRenderbuffer)
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderbuffer)
    if floatComponents {
      glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_RGBA16F), width, height)
    } else {
      glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_RGBA8), width, height)
    }
    glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderbuffer)
    // checkGLErrors()
    
    var depthRenderbuffer: GLuint = 0
    glGenRenderbuffers(1, &depthRenderbuffer)
    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), depthRenderbuffer)
    glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT24), width, height)
    glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), depthRenderbuffer)
    // checkGLErrors()
    
    let framebufferStatus = Int32(glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)))
    assert(framebufferStatus == GL_FRAMEBUFFER_COMPLETE)
    if framebufferStatus != GL_FRAMEBUFFER_COMPLETE {
      return nil
    }
    
    // clear buffer
    glViewport(0, 0, width, height)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
    // checkGLErrors()
    
    // render
    render(atTime: time)
    // checkGLErrors()
    
    // create the image
    if floatComponents { // float components (16-bits of actual precision)
      
      // slurp bytes out of OpenGL
      typealias ComponentType = Float
      
      var imageRawBuffer = [ComponentType](repeating: 0, count: Int(width * height) * samplesPerPixel * MemoryLayout<ComponentType>.size)
      glReadPixels(GLint(0), GLint(0), width, height, GLenum(GL_RGBA), GLenum(GL_FLOAT), &imageRawBuffer)
      
      // flip image vertically — OpenGL has a different 'up' than CoreGraphics
      let rowLength = Int(width) * samplesPerPixel
      for rowIndex in 0..<(Int(height) / 2) {
        let baseIndex = rowIndex * rowLength
        let destinationIndex = (Int(height) - 1 - rowIndex) * rowLength
        for i in 0 ..< rowLength {
          imageRawBuffer.swapAt(baseIndex + i, destinationIndex + i)
        }
      }
      
      // make the CGImage
      var imageBuffer = vImage_Buffer(
        data: UnsafeMutablePointer<ComponentType>(mutating: imageRawBuffer),
        height: vImagePixelCount(height),
        width: vImagePixelCount(width),
        rowBytes: Int(width) * MemoryLayout<ComponentType>.size * samplesPerPixel)
      
      var format = vImage_CGImageFormat(
        bitsPerComponent: UInt32(MemoryLayout<ComponentType>.size * 8),
        bitsPerPixel: UInt32(MemoryLayout<ComponentType>.size * samplesPerPixel * 8),
        colorSpace: nil, // defaults to sRGB
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue | CGBitmapInfo.floatComponents.rawValue),
        version: UInt32(0),
        decode: nil,
        renderingIntent: .defaultIntent)
      
      var error: vImage_Error = 0
      thumbnailCGImage = vImageCreateCGImageFromBuffer(&imageBuffer, &format, nil, nil, vImage_Flags(kvImagePrintDiagnosticsToConsole), &error)!.takeRetainedValue()
      
    } else { // byte components
      
      // slurp bytes out of OpenGL
      typealias ComponentType = UInt8
      
      var imageRawBuffer = [ComponentType](repeating: 0, count: Int(width * height) * samplesPerPixel * MemoryLayout<ComponentType>.size)
      glReadPixels(GLint(0), GLint(0), width, height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &imageRawBuffer)
      
      // flip image vertically — OpenGL has a different 'up' than CoreGraphics
      let rowLength = Int(width) * samplesPerPixel
      for rowIndex in 0..<(Int(height) / 2) {
        let baseIndex = rowIndex * rowLength
        let destinationIndex = (Int(height) - 1 - rowIndex) * rowLength
        for i in 0 ..< rowLength {
          imageRawBuffer.swapAt(baseIndex + i, destinationIndex + i)
        }
      }
      
      // make the CGImage
      var imageBuffer = vImage_Buffer(
        data: UnsafeMutablePointer<ComponentType>(mutating: imageRawBuffer),
        height: vImagePixelCount(height),
        width: vImagePixelCount(width),
        rowBytes: Int(width) * MemoryLayout<ComponentType>.size * samplesPerPixel)
      
      var format = vImage_CGImageFormat(
        bitsPerComponent: UInt32(MemoryLayout<ComponentType>.size * 8),
        bitsPerPixel: UInt32(MemoryLayout<ComponentType>.size * samplesPerPixel * 8),
        colorSpace: nil, // defaults to sRGB
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
        version: UInt32(0),
        decode: nil,
        renderingIntent: .defaultIntent)
      
      var error: vImage_Error = 0
      thumbnailCGImage = vImageCreateCGImageFromBuffer(&imageBuffer, &format, nil, nil, vImage_Flags(kvImagePrintDiagnosticsToConsole), &error)!.takeRetainedValue()
    }
    
    #if os(iOS)
      objc_sync_exit(glContext)
      if oldGLContext != nil {
        EAGLContext.setCurrentContext(oldGLContext)
      }
    #elseif os(OSX)
      CGLUnlockContext(glContext)
      if oldGLContext != nil {
        CGLSetCurrentContext(oldGLContext)
      }
    #endif
    
    return thumbnailCGImage
  }
}

func checkGLErrors() {
  var glError: GLenum
  var hadError = false
  repeat {
    glError = glGetError()
    if glError != 0 {
      NSLog("OpenGL error %#x", glError)
      hadError = true
    }
  } while glError != 0
  assert(!hadError)
}

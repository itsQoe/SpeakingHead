//
//  SHWaveformView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 18.10.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

//
//  FDWaveformView
//
//  Created by William Entriken on 10/6/13.
//  Copyright (c) 2016 William Entriken. All rights reserved.
//

import AppKit
import AVFoundation
import Accelerate

class SHWaveformView: NSView {
  
  var delegate: SHWaveformViewDelegate?
  
  var audioURL: URL? = nil {
    didSet {      
      if let audioURL = self.audioURL {
        let asset = AVURLAsset(url: audioURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)])
        self.asset = asset
        
        guard let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
          let alert = NSAlert()
          alert.messageText = "Failed to load asset track for audio file \(audioURL.absoluteString)"
          alert.runModal()
          return
        }
        
        self.assetTrack = assetTrack
        loadingInProgress = true
        
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
          var error: NSError? = nil
          let status = self.asset!.statusOfValue(forKey: "duration", error: &error)
          switch status {
          case .loaded:
            // self.imageView.image = nil
            let formatDesc = assetTrack.formatDescriptions
            let item = formatDesc.first as! CMAudioFormatDescription
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(item)
            let samples = asbd!.pointee.mSampleRate * Float64(self.asset!.duration.value) / Float64(self.asset!.duration.timescale)
            self.totalSamples = Int(samples)
            self.zoomEndSamples = Int(samples)
            self.updateFlag = true
            self.needsRender = true
          case .failed, .cancelled, .loading, .unknown:
            let alert = NSAlert()
            alert.messageText = "Failed to load asset track for audio file \(audioURL.absoluteString)"
            alert.informativeText = error?.localizedDescription ?? ""
            alert.runModal()
          }
          self.loadingInProgress = false
        }        
      } else {
        self.asset = nil
        self.assetTrack = nil
        self.imageView.image = nil
      }
    }
  }
  
  var animTimer: Timer?
  let animTimerInterval = TimeInterval(0.01)
  var animRange: ClosedRange<TimeInterval> = 0.0 ... 0.0
  var animSpeed: Double = 1.0
  var animStartTime: TimeInterval = 0.0
  
  @objc dynamic var zoom: Double = 0.0 {
    didSet {
      updateLayout()
      needsRender = true
    }
  }
  var minPPS: Double = 300.0
  var maxPPS: Double = 1000.0
  var pixel_per_second: Double {
    return minPPS + (maxPPS - minPPS) * zoom
  }

  var infoPanel: SHInfoPanel?
  
  var audioRange: ClosedRange<CGFloat> = 0...0
  var audioPlayer: AVAudioPlayer?
  
  private var shiftState: Bool = false
  var updateFlag: Bool = false
  var needsRender: Bool = false
  
  var cursorIsHidden: Bool {
    get {
      return controlView.audioCursorIsHidden
    }
    set(isHidden) {
      controlView.audioCursorIsHidden = isHidden
    }
  }
  
  var cursorPosition: Double = 0.0 {
    didSet {
      updateLayout()
    }
  }
  
  var selectedRange: ClosedRange<Double>? {
    didSet {
      updateLayout()
    }
  }
  
  var activeRange: ClosedRange<Double> = 0.0 ... 0.0
  
  fileprivate(set) var totalSamples = 0
  
  var zoomStartSamples: Int = 0
  
  var zoomEndSamples: Int = 0
  
  fileprivate func decibel(amplitude: CGFloat) -> CGFloat {
    return 20.0 * log10(abs(amplitude))
  }
  
  @objc dynamic var wavesColor = NSColor.gray {
    didSet {
      controlView.baselineColor = wavesColor
      needsRender = true
      updateFlag = true
      needsDisplay = true
    }
  }
  
  @objc dynamic var selectionColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.0, alpha: 0.5) {
    didSet {
      controlView.selectionColor = selectionColor
    }
  }
  
  @objc dynamic var cursorColor = NSColor.red {
    didSet {
      controlView.audioCursorColor = cursorColor
    }
  }
  
  var cursorWidth: CGFloat = 1.0 {
    didSet {
      controlView.audioCursorWidth = cursorWidth
    }
  }
  
  /// Drawing more pixels than shown to get antialiasing, 1.0 = no overdraw, 2.0 = twice as many pixels
  fileprivate var horizontalMinimumOverdraw: CGFloat = 1.0
  
  /// Drawing more pixels than shown to get antialiasing, 1.0 = no overdraw, 2.0 = twice as many pixels
  fileprivate var horizontalMaximumOverdraw: CGFloat = 1.0
  
  /// Drawing more pixels than shown to get antialiasing, 1.0 = no overdraw, 2.0 = twice as many pixels
  fileprivate var horizontalTargetOverdraw: CGFloat = 1.0
  
  /// Drawing more pixels than shown to get antialiasing, 1.0 = no overdraw, 2.0 = twice as many pixels
  fileprivate var verticalMinimumOverdraw: CGFloat = 1.0
  
  /// Drawing more pixels than shown to get antialiasing, 1.0 = no overdraw, 2.0 = twice as many pixels
  fileprivate var verticalMaximumOverdraw: CGFloat = 1.0
  
  /// Drawing more pixels than shown to get antialiasing, 1.0 = no overdraw, 2.0 = twice as many pixels
  fileprivate var verticalTargetOverdraw: CGFloat = 1.0
  
  /// The "zero" level (in dB)
  fileprivate let noiseFloor: CGFloat = -50.0
  
  // Mouse down position
  fileprivate var mouseDownX: CGFloat = 0.0
  
  let imageView: NSImageView = NSImageView(frame: CGRect.zero)
  let controlView: AudioControlView = AudioControlView(frame: CGRect.zero)
  
  fileprivate var asset: AVAsset?
  fileprivate var assetTrack: AVAssetTrack?
  fileprivate var cachedSampleRange: CountableRange<Int> = 0..<0
  fileprivate var renderingInProgress = false
  fileprivate var loadingInProgress = false
  
  // MARK: Initialization
  
  required public init?(coder aCoder: NSCoder) {
    super.init(coder: aCoder)
    self.setup()
  }
  
  override init(frame rect: CGRect) {
    super.init(frame: rect)
    self.setup()
  }
  
  func setup() {
    self.autoresizesSubviews = false
    self.wantsLayer = true
    
    imageView.imageScaling = .scaleAxesIndependently
    addSubview(imageView)
    
    controlView.wantsLayer = true
    controlView.layerContentsRedrawPolicy = NSView.LayerContentsRedrawPolicy.onSetNeedsDisplay
    controlView.audioCursorColor = cursorColor
    controlView.audioCursorWidth = cursorWidth
    controlView.mouseCursorColor = NSColor.lightGray
    controlView.mouseCursorWidth = cursorWidth
    controlView.selectionColor = selectionColor
    controlView.baselineColor = wavesColor
    controlView.baselineWidth = 1.0
    controlView.baselineHeight = self.bounds.height / 2.0 - 1.0
    controlView.baselineIsHidden = false
    controlView.frame = self.bounds
    addSubview(controlView)
    
    self.infoPanel = SHInfoPanel()
    let opts = NSTrackingArea.Options([NSTrackingArea.Options.activeInActiveApp, NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.mouseEnteredAndExited])
    self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: opts, owner: self, userInfo: nil))
    
    updateLayout()
  }
  
  // MARK: Mouse events
  
  override func mouseEntered(with event: NSEvent) {
    infoPanel?.orderFront(self)
    controlView.mouseCursorIsHidden = false
  }
  
  override func mouseExited(with event: NSEvent) {
    infoPanel?.orderOut(self)
    controlView.mouseCursorIsHidden = true
  }
  
  override func mouseMoved(with event: NSEvent) {
    let windowP = event.locationInWindow
    let p = self.convert(windowP, from: nil)
    
    controlView.mouseCursorIsHidden = false
    controlView.mouseCursorPosition = p.x
    
    let t = Double(p.x) / pixel_per_second
    let pp = NSMakePoint(windowP.x + 10, windowP.y - 30)
    self.infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: pp, size: CGSize.zero)).origin)
    self.infoPanel?.text = String.localizedStringWithFormat("%.3f s", t)
  }
  
  override func mouseUp(with event: NSEvent) {
    let p = self.convert(event.locationInWindow, from: nil)
    
    if controlView.selectionIsHidden {
      cursorPosition = Double(p.x) / pixel_per_second
      controlView.audioCursorIsHidden = false
    } else if let range = selectedRange {
      cursorPosition = range.lowerBound
    }
  }
  
  override func mouseDragged(with event: NSEvent) {
    let windowP = event.locationInWindow
    let p = self.convert(windowP, from: nil)
    let clampedX = clamp(value: p.x, lower: 0.0, upper: frame.size.width)
    selectedRange = Double(min(mouseDownX, clampedX)) / pixel_per_second ... Double(max(mouseDownX, clampedX)) / pixel_per_second
    
    controlView.selectionIsHidden = false

    // info panel
    guard let select = selectedRange else {
      return
    }
    
    controlView.mouseCursorIsHidden = true
    let t = select.upperBound - select.lowerBound
    let pp = NSMakePoint(windowP.x + 10, windowP.y - 30)
    self.infoPanel?.setFrameOrigin(self.window!.convertToScreen(CGRect(origin: pp, size: CGSize.zero)).origin)
    self.infoPanel?.text = String.localizedStringWithFormat("%.3f s", t)
    delegate?.updatePosition(at: clampedX)
  }
  
  override func mouseDown(with event: NSEvent) {
    let p = self.convert(event.locationInWindow, from: nil)
    mouseDownX = p.x
    controlView.audioCursorPosition = p.x
    controlView.mouseCursorIsHidden = true
    controlView.selectionIsHidden = true
    selectedRange = nil
  }
  
  // MARK: Stuff
  func updateLayout() {    
    if let asset = asset {
      audioRange = 0.0 ... CGFloat(asset.duration.seconds * pixel_per_second)
    }
    
    self.imageView.frame = NSMakeRect(audioRange.lowerBound, 0.0, 
                                      audioRange.upperBound - audioRange.lowerBound, 
                                      self.frame.size.height)
    
    controlView.frame = self.bounds
    controlView.needsDisplay = true
    updateFlag = false
    controlView.audioCursorPosition = CGFloat(cursorPosition * pixel_per_second)
    if let select = selectedRange {
      if select.upperBound > activeRange.upperBound {
        if select.lowerBound > activeRange.upperBound {
          selectedRange = nil
          controlView.selectionIsHidden = true
          cursorPosition = 0.0
        } else {
          selectedRange = select.lowerBound ... activeRange.upperBound
          cursorPosition = select.lowerBound
          controlView.selectionRange = CGFloat(select.lowerBound * pixel_per_second) ... CGFloat(activeRange.upperBound)
        }
      } else {
        controlView.selectionRange =
          CGFloat(select.lowerBound * pixel_per_second) ... CGFloat(select.upperBound * pixel_per_second)
      }
    } else if cursorPosition > Double(self.frame.size.width) {
      cursorPosition = 0.0
    }
  }
  
  func updateImage() {
    guard self.assetTrack != nil else {
      return
    }
    let frameWidth = self.frame.size.width
    let boundsHeight = self.bounds.size.height
    DispatchQueue.global(qos: .background).async {
      self.renderAsset(width: frameWidth, height: boundsHeight)
    }
  }
  
  // MARK: Rendering
  override func draw(_ dirtyRect: NSRect) {
    if updateFlag {
      updateLayout()
    }
    
    if needsRender {
      updateImage()
    }
    super.draw(dirtyRect)
  }
  
  func animateCursor(range: ClosedRange<Double>, speed: Double) {
    stopCursor()
    cursorIsHidden = false
    animRange = range
    animSpeed = speed
    animStartTime = ProcessInfo.processInfo.systemUptime 
    animTimer = Timer.scheduledTimer(timeInterval: animTimerInterval, 
                                      target: self, 
                                      selector: #selector(updateCursor), 
                                      userInfo: nil, 
                                      repeats: true)

  }
  
  @objc func updateCursor() {
      let elapsedTime = ProcessInfo.processInfo.systemUptime - animStartTime
      let duration = (animRange.upperBound - animRange.lowerBound) / animSpeed
      if elapsedTime >= duration {
        stopCursor()
      } else {
        let newPos = animRange.lowerBound + elapsedTime * animSpeed
        self.controlView.audioCursorPosition = CGFloat(newPos * self.pixel_per_second)
      }
  }
  
  func stopCursor() {
    if let timer = animTimer {
      timer.invalidate()
      animTimer = nil
    }
    self.cursorPosition = Double(controlView.audioCursorPosition) / pixel_per_second
  }
  
  func renderAsset(width frameWidth: CGFloat, height frameHeight: CGFloat) {
    guard !renderingInProgress && asset != nil else {
      return
    }
    
    renderingInProgress = true
    needsRender = false
    
    let displayRange = zoomEndSamples - zoomStartSamples
    
    guard displayRange > 0 else {return}
    
    let renderStartSamples = clamp(value: zoomStartSamples - displayRange, lower: 0, upper: totalSamples)
    let renderEndSamples = clamp(value: zoomEndSamples + displayRange, lower: 0, upper: totalSamples)
    
    let widthInPixels = Int(frameWidth * horizontalTargetOverdraw)
    let heightInPixels = frameHeight * 3
    
    sliceAsset(withRange: 0..<totalSamples, andDownsampleTo: widthInPixels) {
      (samples, sampleMax) in
      self.plotLogGraph(samples, maximumValue: sampleMax, zeroValue: self.noiseFloor, imageHeight: heightInPixels) {
        (image) in
        DispatchQueue.main.async {
          self.imageView.image = image
          self.cachedSampleRange = renderStartSamples ..< renderEndSamples
          self.renderingInProgress = false
          self.updateFlag = true
          self.needsDisplay = true
        }
      }
    }
  }
  
  func sliceAsset(withRange slice: Range<Int>, andDownsampleTo targetSamples: Int, done: (_ samples: [CGFloat], _ sampleMax: CGFloat) -> Void) {
    guard slice.count > 0 else {return}
    guard let asset = asset else {return}
    guard let assetTrack = assetTrack else {return}
    guard let reader = try? AVAssetReader(asset: asset) else {return}
    
    reader.timeRange = CMTimeRangeMake(CMTimeMake(Int64(slice.lowerBound), asset.duration.timescale), 
                                       CMTimeMake(Int64(slice.count), asset.duration.timescale))
    
    let outputSettingsDict: [String: AnyObject] = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM) as AnyObject,
      AVLinearPCMBitDepthKey: 16 as AnyObject,
      AVLinearPCMIsBigEndianKey: false as AnyObject,
      AVLinearPCMIsFloatKey: false as AnyObject,
      AVLinearPCMIsNonInterleaved: false as AnyObject
    ]
    
    let readerOutput = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: outputSettingsDict)
    readerOutput.alwaysCopiesSampleData = false
    reader.add(readerOutput)
    
    var channelCount = 1
    let formatDesc: [AnyObject] = assetTrack.formatDescriptions as [AnyObject]
    for item in formatDesc {
      let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item as! CMAudioFormatDescription)
      guard fmtDesc != nil else {return}
      channelCount = Int(fmtDesc!.pointee.mChannelsPerFrame)
    }
    
    var sampleMax = noiseFloor
    var samplesPerPixel = channelCount * slice.count / targetSamples
    if samplesPerPixel < 1 {
      samplesPerPixel = 1
    }
    
    var outputSamples = [CGFloat]()
    var nextDataOffset = 0
    
    // 16-bit samples
    reader.startReading()
    
    while reader.status == .reading {
      guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(), 
            let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
        break
      }
      
      let readBufferLength = CMBlockBufferGetDataLength(readBuffer)
      
      var data = Data(capacity: readBufferLength)
      data.withUnsafeMutableBytes {
        (bytes: UnsafeMutablePointer<Int16>) in
        CMBlockBufferCopyDataBytes(readBuffer, 0, readBufferLength, bytes)
        let samples = UnsafeMutablePointer<Int16>(bytes)
        
        CMSampleBufferInvalidate(readSampleBuffer)
        
        let samplesToProcess = readBufferLength / MemoryLayout<Int16>.size
        
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
        
        let sampleCount = vDSP_Length(samplesToProcess)
        
        vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
        
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
        
        var zero: Float = 32768.0
        vDSP_vdbcon(processingBuffer, 1, &zero, &processingBuffer, 1, sampleCount, 1)
        
        var ceil: Float = 0.0
        var noiseFloorFloat = Float(noiseFloor)
        vDSP_vclip(processingBuffer, 1, &noiseFloorFloat, &ceil, &processingBuffer, 1, sampleCount)
        
        let downSampledLength = samplesToProcess / samplesPerPixel
        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
        
        vDSP_desamp(processingBuffer, 
                    vDSP_Stride(samplesPerPixel), 
                    filter, 
                    &downSampledData, 
                    vDSP_Length(downSampledLength), 
                    vDSP_Length(samplesPerPixel))
        
        let downSampledDataCG = downSampledData.map {
          (value: Float) -> CGFloat in
          let element = CGFloat(value)
          if element > sampleMax {
            sampleMax = element
          }
          return element
        }
        
        outputSamples += downSampledDataCG
        nextDataOffset += downSampledLength
      }
    }
    
    if reader.status == .completed {
      done(outputSamples, sampleMax)
    }
  }
  
  func plotLogGraph(_ samples: [CGFloat], 
                    maximumValue max: CGFloat, 
                    zeroValue min: CGFloat, 
                    imageHeight: CGFloat, 
                    done: (_ image: NSImage) -> Void)
  {
    let imageSize = CGSize(width: CGFloat(samples.count), height: imageHeight)
    let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, 
                                    pixelsWide: Int(imageSize.width), 
                                    pixelsHigh: Int(imageSize.height), 
                                    bitsPerSample: 8, 
                                    samplesPerPixel: 4, 
                                    hasAlpha: true, 
                                    isPlanar: false, 
                                    colorSpaceName: NSColorSpaceName.calibratedRGB, 
                                    bitmapFormat: NSBitmapImageRep.Format(rawValue: UInt(0)), 
                                    bytesPerRow: 0, 
                                    bitsPerPixel: 0)
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: imageRep!)
    
    if let context = NSGraphicsContext.current?.cgContext, let rep = imageRep {
      context.setShouldAntialias(false)
      context.setAlpha(1.0)
      context.setLineWidth(1.0)
      context.setStrokeColor(self.wavesColor.cgColor)
      
      let sampleDrawingScale: CGFloat
      if max == min {
        sampleDrawingScale = 0
      } else {
        sampleDrawingScale = imageHeight / 2 / (max - min)
      }
      
      let verticalMiddle = imageHeight / 2
      for (x, sample) in samples.enumerated() {
        let height = (sample - min) * sampleDrawingScale
        context.move(to: CGPoint(x: CGFloat(x), y: verticalMiddle - height))
        context.addLine(to: CGPoint(x: CGFloat(x), y: verticalMiddle + height))
        context.strokePath()
      }
      
      let image = NSImage(size: rep.size)
      image.addRepresentation(rep)
      
      NSGraphicsContext.restoreGraphicsState()
      done(image)
    }
  }
}

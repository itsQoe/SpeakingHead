//
//  HeadViewController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 07.09.15.
//  Copyright (c) 2015 Uli Held. All rights reserved.
//

import SceneKit
import SpriteKit
import SceneKit.ModelIO
import AVFoundation

private var KVOContext: Int = 0

enum UserInput {
  case yes, no, cancel
}

class AnimationController: NSViewController, IPATextViewDelegate, AVAudioPlayerDelegate, IPASymbolsDelegate, SHWaveformViewDelegate {

  @IBOutlet weak var window: NSWindow?
  @IBOutlet weak var userDefaultsController: NSUserDefaultsController?
  @IBOutlet weak var controlView: NSView?
  @IBOutlet weak var playButton: NSButton?
  @IBOutlet weak var playMenuItem: NSMenuItem?
  @IBOutlet weak var openRecentMenu: NSMenu?
  @IBOutlet weak var textView: IPATextView?
  @IBOutlet weak var audioView: SHWaveformView?
  @IBOutlet weak var stackView: NSStackView?
  @IBOutlet weak var scrollView: NSScrollView?
  @IBOutlet weak var messageView: NSTextField?
  @IBOutlet weak var sliderPopover: NSPopover?
  @IBOutlet weak var speedTextField: NSTextField?
  @IBOutlet weak var speedSlider: NSSlider?
  @IBOutlet weak var ipaPopover: NSPopover?
  @IBOutlet weak var ipaSymbolsViewController: IPASymbolsViewController?
  @IBOutlet weak var ipaPopoverButton: NSButton?
  @IBOutlet weak var defaultPopover: NSPopover?
  @IBOutlet weak var defaultPopoverController: DefaultPopoverController?
  @IBOutlet weak var perspectivesPopover: NSPopover?
  @IBOutlet weak var perspectivesController: PerspectiveCollectionViewController?
  
  let SUPPORTED_AV_EXTENSIONS: [String] = [
    "aac",
    "adts",
    "ac3",
    "aif",
    "aiff",
    "aifc",
    "aiff",
    "caf",
    "mp3",
    "mp4",
    "m4a",
    "snd",
    "au",
    "sd2",
    "wav"
  ]
  
  var perspectiveCollection: SHPerspectiveCollection?
  
  @objc dynamic var saveFileName: String? {
    didSet {
      if let name = saveFileName {
        self.window?.setTitleWithRepresentedFilename(name)
      } else {
        self.window?.setTitleWithRepresentedFilename("SpeakingHead")
      }
    }
  }
  
  var saveFileURL: URL? {
    didSet {
      if let url = saveFileURL {
        saveFileName = url.lastPathComponent
        if let defaults = userDefaultsController?.defaults {
          let urlData = NSKeyedArchiver.archivedData(withRootObject: url)
          defaults.set(urlData, forKey: save_file_key)
        }
      } else {
        saveFileName = nil
        if let defaults = userDefaultsController?.defaults {
          defaults.set(Data(), forKey: save_file_key)
        }
      }
    }
  }
  
  var recentFiles: [URL] = [URL]()
  var fileBookmarks: [URL: Data] = [URL: Data]()
  var audioBookmarks: [URL: Data] = [URL: Data]()
  
  var hasUnsavedChanges: Bool = false {
    didSet {
      if hasUnsavedChanges {
        self.saveFileName = (saveFileURL?.lastPathComponent ?? "") + " (unsaved)"
      } else {
        self.saveFileName = saveFileURL?.lastPathComponent ?? nil
      }
    }
  }
  var headView: HeadView?
  var sceneFactory: SceneFactory?
  var animFactory: AnimationFactory?
  var animation: HeadAnimation?
  
  @objc dynamic var animSpeed: NSNumber = 1.0 {
    didSet {
      let defaults = UserDefaults.standard
      defaults.set(animSpeed, forKey: speed_key)
    }
  }
  
  @objc dynamic var animRepeat: Bool = false
  
  var maxZoomDelta: Double = 0.1
  var shiftState: Bool = false
  
  @objc dynamic var zoom: Double = 0.0 {
    didSet {
      textView?.zoom = zoom
      audioView?.zoom = zoom
      updateLayout()
      if let scrollView = scrollView {
        let visibleRect = scrollView.documentVisibleRect
        let oldPPS = CGFloat(minPPS + (maxPPS - minPPS) * oldValue)
        let pps = CGFloat(minPPS + (maxPPS - minPPS) * zoom)
        let x = visibleRect.origin.x / oldPPS * pps
        let y = scrollView.contentView.bounds.minY
        scrollView.contentView.scroll(to: NSMakePoint(x, y))
      }
    }
  }
  
  private let maxOpenRecentCount: Int = 50
  
  private let minPPS: Double = 300.0
  private let maxPPS: Double = 2000.0
  private var pixel_per_second: Double {
    return minPPS + (maxPPS - minPPS) * zoom
  }
  
//  var perspectives: [SHPerspectiveData] = [SHPerspectiveData]()
  
  @objc dynamic var muteAudio: NSControl.StateValue = NSControl.StateValue.off {
    didSet {
      audioPlayer?.volume = muteAudio == NSControl.StateValue.off ? 1.0 : 0.0
    }
  }
  
  var isPlaying: Bool = false {
    didSet {
      if let scene = self.headView?.scene {
        if !isPlaying {
          scene.isPaused = true
        }
      }
      if isPlaying {
        playButton?.state = NSControl.StateValue.on
        playMenuItem?.state = NSControl.StateValue.on
      } else {
        playButton?.state = NSControl.StateValue.off
        playMenuItem?.state = NSControl.StateValue.off
      }
    }
  }
  
  private var currentDuration: CFTimeInterval = 0.0
  private var animDuration: CFTimeInterval = 0.0
  private var audioDuration: CFTimeInterval = 0.0
  private var timer: Timer?
  private var ipaStringDidChange: Bool = false
  
  private var audioWidth: CGFloat = 0.0

  private var audioPlayer: AVAudioPlayer? {
    didSet {
      audioView?.audioPlayer = audioPlayer
    }
  }
  // var audioPlayer: AKAudioPlayer?
    
  private var timeCursor: Double {
    get {
      if let audioView = self.audioView {
        return audioView.cursorPosition
      }
      return 0.0
    }
    set(time) {
      if let audioView = self.audioView {
        audioView.cursorPosition = time
      }
    }
  }
  
  private var selectedRange: ClosedRange<Double>? {
    get {
      if let audioView = self.audioView {
        if let selectedRange = audioView.selectedRange {
          return selectedRange
        }
      }
      return nil
    }
  }
  
  
  // MARK: Initialisation
  override func viewDidLoad() {
    // Recent files
    if let defaults = self.userDefaultsController?.defaults {
      if let recentData = defaults.data(forKey: recent_files_key) {
        if let files = NSKeyedUnarchiver.unarchiveObject(with: recentData) as? [URL] {
          self.recentFiles = files
        }
      }
      
      if let bookmarkData = defaults.data(forKey: files_bookmark_key) {
        if let bookmarks = NSKeyedUnarchiver.unarchiveObject(with: bookmarkData) as? [URL: Data] {
          self.fileBookmarks = bookmarks
        }
      }
      
      if let bookmarkData = defaults.data(forKey: audio_bookmark_key) {
        if let bookmarks = NSKeyedUnarchiver.unarchiveObject(with: bookmarkData) as? [URL: Data] {
          self.audioBookmarks = bookmarks
        }
      }
    }
    
    textView!.maxPPS = self.maxPPS
    textView!.delegate = self
    textView!.bind(NSBindingName(rawValue: "autoPopover"), 
                   to: userDefaultsController!, 
                   withKeyPath: "values."+auto_ipa_popover_key, 
                   options: nil)
    textView!.bind(NSBindingName(rawValue: "cursorColor"), 
                   to: userDefaultsController!, 
                   withKeyPath: "values."+text_cursor_color_key, 
                   options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
    textView!.bind(NSBindingName(rawValue: "selectionColor"), 
                   to: userDefaultsController!, 
                   withKeyPath: "values."+text_selection_color_key, 
                   options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
    textView!.bind(NSBindingName(rawValue: "primaryIndicatorColor"),
                   to: userDefaultsController!, 
                   withKeyPath: "values."+primary_indicator_color_key, 
                   options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
    textView!.bind(NSBindingName(rawValue: "secondaryIndicatorColor"), 
                   to: userDefaultsController!, 
                   withKeyPath: "values."+secondary_indicator_color_key, 
                   options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
    
    // AudioView
    audioView!.delegate = self
    audioView!.maxPPS = self.maxPPS
    audioView!.bind(NSBindingName(rawValue: "cursorColor"),
                    to: userDefaultsController!,
                    withKeyPath: "values."+timeline_cursor_color_key,
                    options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
    audioView!.bind(NSBindingName(rawValue: "selectionColor"),
                    to: userDefaultsController!,
                    withKeyPath: "values."+timeline_selection_color_key,
                    options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
    audioView!.bind(NSBindingName(rawValue: "wavesColor"),
                    to: userDefaultsController!,
                    withKeyPath: "values."+audio_color_key,
                    options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
//    audioView!.bind("zoom", to: self, withKeyPath: "zoom", options: nil)
//    self.bind("zoom", to: audioView!, withKeyPath: "zoom", options: nil)
    
    // Scroll View
    scrollView?.contentView.setFrameOrigin(NSMakePoint(0.0, 0.0))
    
    // Anim Speed
    let defaults = UserDefaults.standard
    if let defaultSpeed = defaults.object(forKey: speed_key) as? NSNumber {
      animSpeed = defaultSpeed
    }
    speedTextField?.floatValue = animSpeed.floatValue
    speedSlider?.floatValue = animSpeed.floatValue
    
    self.bind(NSBindingName(rawValue: "animSpeed"),
              to: userDefaultsController!,
              withKeyPath: "values."+speed_key,
              options: nil)
    
    // Get Play Menu Item
    if let mainMenu = NSApplication.shared.mainMenu {
      if let controlsMenu = mainMenu.item(withTitle: "Controls")?.submenu {
        if let item = controlsMenu.item(withTitle: "Play / Pause") {
          playMenuItem = item
        }
        if let item = controlsMenu.item(withTitle: "Mute") {
          item.bind(NSBindingName(rawValue: "state"), to: self, withKeyPath: "muteAudio", options: nil)
        }
      }
    }
    
    // Get Open Recent Manu item
    if let mainMenu = NSApplication.shared.mainMenu {
      if let fileMenu = mainMenu.item(withTitle: "File")?.submenu {
        if let item = fileMenu.item(withTitle: "Open Recent")?.submenu {
          self.openRecentMenu = item
        }
      }
    }
    updateRecentFiles(with: nil)
    
    messageView!.isHidden = true
    
    // update perspectives menu
    self.perspectiveCollection = SHPerspectiveCollection()
    self.perspectiveCollection?.loadPerspectiveData()
    if let mainMenu = NSApplication.shared.mainMenu {
      if let displayMenu = mainMenu.item(withTitle: "Display")?.submenu {
        if let pMenu = displayMenu.item(withTitle: "Perspectives")?.submenu {
          perspectiveCollection?.perspectivesMenu = pMenu
        }
      }
    }
    perspectiveCollection?.updateMenuItems()
    perspectivesController?.perspectives = perspectiveCollection
    
    // TextView
    // load default phone
    if let defaults = self.userDefaultsController?.defaults {
      if let defaultPhoneData = defaults.data(forKey: ipa_default_key) {
        if let phone = NSKeyedUnarchiver.unarchiveObject(with: defaultPhoneData) as? Phone {
          textView!.defaultPhone = phone
        }
      }
    }
    
    // load ipa text from defaults
    if let defaults = self.userDefaultsController?.defaults {
      if let ipaTextData = defaults.data(forKey: ipa_text_key) {
        if let ipaText = NSKeyedUnarchiver.unarchiveObject(with: ipaTextData) as? IPAText {
          textView!.insert(phones: ipaText.phoneArray, inRange: 0 ..< 0, undo: false)
          if let url = ipaText.audioURL {
            self.loadAudioIndirectly(from: url)
          }
        }
      }
    }

    updateLayout()
  }
  
  // receive IPA symbol
  
  func insertIPA(_ ipa: String) {
    textView?.insertText(ipa, replacementRange: NSRange())
    window?.makeFirstResponder(textView)
  }
  
  // MARK: IPATextView Delegate
  
  func textDidChange(sender: IPATextView) {
    saveToDefaults()
    ipaStringDidChange = true
    hasUnsavedChanges = true
    updateLayout()
    updatePosition(at: textView!.manipulationAt)
  }
  
  func textDidResize(sender: IPATextView) {
    updateLayout()
    updatePosition(at: textView!.manipulationAt)
  }
  
  func errorMessage(sender: AnyObject, message: String) {
    messageView?.isHidden = false
    messageView?.stringValue = message
  }
    
  // MARK: Update Views
  override func viewDidLayout() {
    let maxX = max(audioView!.audioRange.upperBound, textView!.textRange.upperBound)
    let visibleX = scrollView?.frame.size.width ?? 0.0
    
    stackView?.setFrameSize(NSSize(width: max(maxX, visibleX), 
                                   height: stackView!.frame.size.height))
    
    super.viewDidLayout()
  }
  
  func updateLayout() {
    let maxX = max(audioView!.audioRange.upperBound, textView!.textRange.upperBound)
    let maxS = Double(maxX) / pixel_per_second
    let visibleX = scrollView?.frame.size.width ?? 0.0
    
    stackView?.setFrameSize(NSSize(width: max(maxX, visibleX), 
                                   height: stackView!.frame.size.height))

    audioView?.setFrameSize(NSSize(width: maxX, 
                                   height: audioView!.frame.size.height))
    audioView?.activeRange = 0.0 ... maxS
    audioView?.updateLayout()
  }
  
  func updatePosition(at pos: CGFloat) {
    guard let scrollView = scrollView else {return}
    let visibleRect = scrollView.documentVisibleRect
    if pos < visibleRect.origin.x {
      scrollView.contentView.scroll(NSPoint(x: max(0.0, pos), y: 0.0))
    } else if pos > visibleRect.origin.x + visibleRect.width - 10  {
      scrollView.contentView.scroll(NSPoint(x: max(0.0, pos - visibleRect.width + 10), y: 0.0))
    }
  }
  
  func updateRecentFiles(with url: URL?) {
    if let url = url {
      if let index = recentFiles.index(of: url) {
        recentFiles.remove(at: index)
      }
      recentFiles.append(url)
      
      if recentFiles.count > maxOpenRecentCount {
        recentFiles.removeFirst()
      }
      
      do {
        let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        fileBookmarks[url] = bookmarkData
      } catch {
        let alert = NSAlert()
        alert.messageText = "Warning: Unable to create security bookmark."
        alert.runModal()
      }
      
      // save in defaults
      let recentData = NSKeyedArchiver.archivedData(withRootObject: recentFiles)
      if let defaults = userDefaultsController?.defaults {
        defaults.set(recentData, forKey: recent_files_key)
      }
      self.writeBookmarksToDefault()
    }
    openRecentMenu?.removeAllItems()
    for file in recentFiles.reversed() {
      let newItem = NSMenuItem(title: file.lastPathComponent, action: #selector(openRecent(_:)), keyEquivalent: "")
      newItem.tag = recentFiles.index(of: file) ?? 0
      openRecentMenu?.addItem(newItem)
    }
  }
  
  func writeBookmarksToDefault() {
    let bookmarksData = NSKeyedArchiver.archivedData(withRootObject: fileBookmarks)
    if let defaults = userDefaultsController?.defaults {
      defaults.set(bookmarksData, forKey: files_bookmark_key)
    }
  }
  
  func writeAudioBookmarksToDefault() {
    let bookmarksData = NSKeyedArchiver.archivedData(withRootObject: audioBookmarks)
    if let defaults = userDefaultsController?.defaults {
      defaults.set(bookmarksData, forKey: audio_bookmark_key)
    }
  }
  
  func saveToDefaults() {
    if let defaults = self.userDefaultsController?.defaults {
      let ipaText = IPAText()
      ipaText.phoneArray = textView?.phones
      ipaText.audioURL = audioView?.audioURL
      let ipaTextData = NSKeyedArchiver.archivedData(withRootObject: ipaText)
      defaults.set(ipaTextData, forKey: ipa_text_key)
    }
  }
  
  // MARK: Controls
  
  func loadAudio(_ url: URL) -> Bool {
    removeAudio()
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: url)
      if audioPlayer!.duration > 120 {
        let alert = NSAlert()
        alert.messageText = "Audio file imports with a duration grater than 120 seconds are currently not suported."
        alert.runModal()
        audioPlayer = nil
        audioView?.audioURL = nil
        saveToDefaults()
        return false
      }
      loadAudio(withURL: url, duration: audioPlayer!.duration)
      audioPlayer?.delegate = self
      audioPlayer?.enableRate = true
      audioPlayer?.rate = Float(truncating: animSpeed)
      audioPlayer?.volume = muteAudio == NSControl.StateValue.off ? 1.0 : 0.0
      // audioPlayer?.rate = 2.0
      audioPlayer?.prepareToPlay()
      audioDuration = audioPlayer!.duration
      currentDuration = max(animDuration, audioDuration)
    } catch {
      let alert = NSAlert()
      alert.messageText = "Unable to load audio file."
      alert.informativeText = url.absoluteString
      alert.runModal()
      return false
    }
    return true
  }
  
  func loadAudio(withURL url: URL, duration: Double) {
    guard audioView != nil else {return}
    stopAnimation()
    audioWidth = CGFloat(duration * pixel_per_second)
    audioView!.audioRange = 0.0 ... audioWidth
    updateLayout()
    audioView!.audioURL = url
    saveToDefaults()
    hasUnsavedChanges = true
  }
  
  func removeAudio() {
    self.stopAnimation()
    audioPlayer = nil
    audioWidth = 0.0
    audioView?.audioRange = 0.0 ... 0.0
    audioView?.audioURL = nil
    audioDuration = 0.0
    updateLayout()
    audioView?.selectedRange = nil
    audioView?.cursorPosition = 0.0
    audioView?.updateLayout()
  }
  
  func createAnimation(phones: [Phone]) {
    guard phones.count > 0 else {
      animation = nil
      return
    }
    if let anim = animFactory?.getAnimation(forPhones: phones) {
      anim.speed = animSpeed.floatValue
      animation = anim
      animDuration = anim.duration
      currentDuration = max(animDuration, audioDuration)
    } else {
      animation = nil
      self.errorMessage(sender: self, message: "Unable to create animation!")
    }
  }
  
  func playAnimation() {
    isPlaying = true
    resetAnimation()
  }
    
  func resetAnimation() {
    animDuration = (animation?.duration ?? 0.0)
    if audioPlayer != nil {
      audioDuration = audioPlayer!.duration
    } else {
      audioDuration = 0.0
    }
    currentDuration = max(animDuration, audioDuration)
    var currentOffset = timeCursor
    
    if let selection = selectedRange {
      if timeCursor < selection.lowerBound || timeCursor >= selection.upperBound {
        currentOffset = selection.lowerBound
      }
      currentDuration = selection.upperBound
    }
    timeCursor = currentOffset
    
    if currentOffset < audioDuration, let player = audioPlayer {
      player.currentTime = currentOffset
      player.rate = Float(truncating: animSpeed)
      player.prepareToPlay()
      player.play()
    }

    // head animation
    if animation != nil {
      animation!.speed = animSpeed.floatValue
      if animation!.head != nil, let head = sceneFactory!.head {
        head.removeAllAnimations()
        if currentOffset < animDuration {
          let currentTime = CACurrentMediaTime()
          animation!.head!.beginTime = currentTime
          animation!.head!.timeOffset = currentOffset
          animation!.head!.speed = animSpeed.floatValue
          head.addAnimation(animation!.head!, forKey: "head_animation")
          headView?.scene?.isPaused = false
        }
      }
    }
    
    // audio animation
    audioView?.animateCursor(range: currentOffset ... currentDuration, speed: animSpeed.doubleValue)
    
    self.timer = Timer.scheduledTimer(
      timeInterval: (currentDuration - currentOffset) / Double(truncating: animSpeed),
      target: self, 
      selector: #selector(onTimer), 
      userInfo: nil, 
      repeats: false)
    
    isPlaying = true
    playButton?.state = NSControl.StateValue.on
  }
  
  func stopAnimation() {
    if animation != nil {
      if animation!.head != nil, let head = sceneFactory!.head {
        head.removeAllAnimations()
      }
    }
    if let player = audioPlayer {
      player.stop()
    }
    
    timer?.invalidate()
    timer = nil
    
    audioView?.stopCursor()
    
    if let selection = selectedRange {
      timeCursor = selection.lowerBound
    } else {
      timeCursor = 0.0
    }
    isPlaying = false
  }
  
  func pauseAnimation() {
    timer?.invalidate()
    timer = nil
    
    audioView?.stopCursor()
    isPlaying = false
    if let player = audioPlayer {
      player.stop()
    }
  }
    
  @objc func onTimer() {
    if animRepeat {
      timeCursor = 0.0
      resetAnimation()
    } else {
      stopAnimation()
    }
  }
  
  // MARK: Animation Controls
    
  @IBAction func onPlay(_ sender: Any) {
    if !isPlaying {
      closeAllPopovers()
      if ipaStringDidChange {
        self.createAnimation(phones: textView!.phones)
        ipaStringDidChange = false
      }
      self.playAnimation()
    } else {
      self.pauseAnimation()
    }
  }
  
  @IBAction func onStop(_ sender: NSButton) {
    self.stopAnimation()
  }
    
  @IBAction func onSpeedSlider(_ sender: NSButton) {
    if sliderPopover!.isShown {
      sliderPopover?.performClose(sender)
    } else {
      sliderPopover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }
  }
  
  @IBAction func onMute(_ sender: Any) {
    self.muteAudio = muteAudio == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
  }
  
  @IBAction func onRepeat(_ sender: Any) {
    self.animRepeat = !animRepeat
  }
  
  // MARK: Popover
  
  @IBAction func onIPAPopover(_ sender: NSView) {
    if ipaPopover!.isShown {
      ipaPopover?.performClose(sender)
    } else {
      requestPopover(sender)
    }
  }
  
  func requestPopover(_ sender: NSView) {
    if !ipaPopover!.isShown {
      closeAllPopovers()
      ipaPopover?.show(relativeTo: ipaPopoverButton!.bounds, of: ipaPopoverButton!, preferredEdge: .minY)
      window?.makeFirstResponder(textView!)
    }
  }
  
  @IBAction func onDefaultPopover(_ sender: NSButton) {
    if defaultPopover!.isShown {
      defaultPopover!.performClose(sender)
    } else {
      closeAllPopovers()
      defaultPopoverController?.defaultPhone = textView!.defaultPhone
      defaultPopover!.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)  
    }
  }
  
  @IBAction func onPerspectivesPopover(_ sender: NSView) {
    if perspectivesPopover!.isShown {
      perspectivesPopover!.performClose(sender)
      window?.makeFirstResponder(headView)
    } else {
      closeAllPopovers()
      perspectivesPopover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
  }
  
  @IBAction func perspectiveMenuItem(_ sender: NSMenuItem) {
    perspectiveActivate(index: sender.tag)
  }
  
  func perspectiveActivate(index: Int) {
    if let perspective = self.perspectiveCollection?.perspectives[index] {
      self.headView?.perspective = perspective
      self.window?.makeFirstResponder(headView!)
      perspectivesPopover!.performClose(self)
    }

  }
  
  func closeAllPopovers() {
    if sliderPopover!.isShown {
      sliderPopover?.performClose(self)
    }
    if ipaPopover!.isShown {
      ipaPopover?.performClose(self)
    }
    if defaultPopover!.isShown {
      defaultPopover?.performClose(self)
    }
    if perspectivesPopover!.isShown {
      perspectivesPopover?.performClose(self)
    }
  }
  
  @IBAction func zoomIn(_ sender: NSButton) {
    let newZoom = zoom + 0.1
    if newZoom > 1.0 {
      zoom = 1.0
    } else {
      zoom = newZoom
    }
  }
  
  @IBAction func zoomOut(_ sender: NSButton) {
    let newZoom = zoom - 0.1
    if newZoom < 0.0 {
      zoom = 0.0
    } else {
      zoom = newZoom
    }
  }
  
  //MARK: Load and Save
  
  func loadAudioDirectly(from url: URL) {
    if self.loadAudio(url) {
      do {
        let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        audioBookmarks[url] = bookmarkData
        writeAudioBookmarksToDefault()
      } catch {
        let alert = NSAlert()
        alert.messageText = "Warning: Unable to create security bookmark."
        alert.runModal()
      }
    }
  }
  
  func loadAudioIndirectly(from url: URL) {
    if let bookmarkData = self.audioBookmarks[url] {
      let errorMessage: String = "Unable to open audio file.\n"
      do {
        var isStale: Bool = false
        let bookmarkURL = try URL(resolvingBookmarkData: bookmarkData,
                                  options: .withSecurityScope,
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &isStale)
        if isStale {
          let alert = NSAlert()
          alert.messageText = errorMessage + "Bookmark is stale."
          alert.informativeText = url.absoluteString
          alert.runModal()
          return
        }
        
        if let accessUrl = bookmarkURL {
          if accessUrl.startAccessingSecurityScopedResource() {
            _ = loadAudio(accessUrl)
            accessUrl.stopAccessingSecurityScopedResource()
          } else {
            let alert = NSAlert()
            alert.messageText = errorMessage + "Access denied."
            alert.informativeText = url.absoluteString
            alert.runModal()
          }
        }
      } catch {
        let alert = NSAlert()
        alert.runModal()
      }
    } else {
      let panel = NSOpenPanel()
      panel.directoryURL = url.deletingLastPathComponent()
      panel.message = "Locate audio file \(url.lastPathComponent)"
      panel.canChooseFiles = true
      panel.canChooseDirectories = false
      panel.allowsMultipleSelection = false
      panel.allowedFileTypes = SUPPORTED_AV_EXTENSIONS
      panel.beginSheetModal(for: self.window!) { (result) -> Void in
        if result == NSApplication.ModalResponse.OK {
          if let newUrl = panel.urls.first {
            self.loadAudioDirectly(from: newUrl)
          }
        } else {
          self.removeAudio()
        }
      }
    }
  }
  
  @objc func openRecent(_ sender: NSMenuItem) {
    let url = recentFiles[sender.tag]
    let alert = NSAlert()
    alert.messageText = "Unable to open file: \(url.debugDescription)."
    if let bookmarkData = fileBookmarks[url] {
      do {
        var isStale: Bool = false
        let bookmarkURL = try URL(resolvingBookmarkData: bookmarkData,
                              options: .withSecurityScope,
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
        if isStale {
          alert.informativeText = "Bookmark is stale."
          alert.runModal()
          return
        }
        
        if let accessUrl = bookmarkURL {
          if accessUrl.startAccessingSecurityScopedResource() {
            loadIPAText(from: accessUrl)
            accessUrl.stopAccessingSecurityScopedResource()
          } else {
            alert.informativeText = "Access denied."
            alert.runModal()
          }
        }
      } catch {
        alert.runModal()
      }
    } else {
      alert.informativeText = "Unable to find security bookmark."
      alert.runModal()
    }
  }
  
  func loadIPAText(from url: URL) {
    stopAnimation()
    do {
      let document = try XMLDocument(contentsOf: url, options: XMLNode.Options(rawValue: 0))
      if let root = document.rootElement() {
        if let ipaText = try IPAText(with: root) {
          if let defaultPhone = ipaText.defaultPhone {
            textView!.defaultPhone = defaultPhone
          }
          textView!.reset(self, withPhones: ipaText.phoneArray)
          if let audioUrl = ipaText.audioURL {
            self.loadAudioIndirectly(from: audioUrl)
          } else {
            self.removeAudio()
          }
          hasUnsavedChanges = false
          saveFileURL = url
          updateRecentFiles(with: url)
        }
      }
    } catch {
      let alert = NSAlert()
      alert.messageText = "Unable to load file \(url.absoluteString)."
      alert.informativeText = "Save file is corrupted."
      alert.runModal()
    }
    
  }
  
  func saveIPATextWithBookmark(to url: URL) {
    let alert = NSAlert()
    alert.messageText = "Unable to write file \(url.absoluteString).\n"
    if let bookmarkData = fileBookmarks[url] {
      do {
        var isStale: Bool = false
        let bookmarkURL = try URL(resolvingBookmarkData: bookmarkData,
                                  options: .withSecurityScope,
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &isStale)
        if isStale {
          alert.informativeText = "Security bookmark is stale."
          alert.runModal()
          return
        }
        
        if let accessUrl = bookmarkURL {
          if accessUrl.startAccessingSecurityScopedResource() {
            _ = saveIPAText(to: accessUrl)
            accessUrl.stopAccessingSecurityScopedResource()
          } else {
            alert.informativeText = "Access denied."
            alert.runModal()
          }
        }
      } catch {
        alert.runModal()
      }
    } else {
      alert.informativeText = "Unable to find security bookmark."
      alert.runModal()
    }
  }
  
  func saveIPATextWithDialog(to url: URL) {
    if self.saveIPAText(to: url) {
      do {
        let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        fileBookmarks[url] = bookmarkData
        writeBookmarksToDefault()
      } catch {
        let alert = NSAlert()
        alert.messageText = "Warning: Unable to create security bookmark."
      }
    }
  }
  
  func saveIPAText(to url: URL) -> Bool {
    let ipaText = IPAText()
    ipaText.audioURL = audioView?.audioURL
    ipaText.defaultPhone = textView?.defaultPhone
    ipaText.phoneArray = textView?.phones
    
    guard let root = ipaText.encodeXML(withKey: "IPAText") as? XMLElement else {
      return false
    }
    
    let document = XMLDocument(rootElement: root)
    document.characterEncoding = "utf8"
    document.version = "1.0"
    document.isStandalone = true
    document.documentContentKind = XMLDocument.ContentKind.xml
    let xmlData: Data = document.xmlData
    do {
      try xmlData.write(to: url)
      hasUnsavedChanges = false
      saveFileURL = url
      updateRecentFiles(with: url)
    } catch {
      let alert = NSAlert()
      alert.messageText = error.localizedDescription
      alert.runModal()
      return false
    }
    return true
  }
  
  func reset() {
    removeAudio()
    stopAnimation()
    animation = nil
    closeAllPopovers()
    textView?.reset(self, withPhones: nil)
    textView?.defaultPhone = Phone()
    saveFileURL = nil
    ipaStringDidChange = false
  }
}

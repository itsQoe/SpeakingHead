//
//  MainWindowController.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 06.04.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import Cocoa
import SceneKit
import AVFoundation

let mainWindowTitle = "Speaking Head"

class MainWindowController: NSWindowController, SCNProgramDelegate, MaterialFactoryDelegate {
  
  @IBOutlet weak var parentView: NSView?
  @IBOutlet weak var animController: AnimationController?
  @IBOutlet weak var textView: IPATextView?
  @IBOutlet weak var userDefaultsController: NSUserDefaultsController?
  
  var headView: HeadView?
  var miniView: MiniHeadView?
  
  var morphWindowController: MorphWindowController?
  var animToolController: AnimationToolController?
  var imageExportController: ImageExportController?
  
  var animFactory: AnimationFactory?
  var sceneFactory: SceneFactory?
  var materialFactory: MaterialFactory?
  var miniMaterialFactory: MiniMaterialFactory?
  
  var headTargetList: [String]?
  var headTargetMap: [String: String]?
  
  override var windowNibName: NSNib.Name? {
    return NSNib.Name("MainWindowController")
  }
  
  // MARK: Initialisation
  
  override func windowDidLoad() {
    super.windowDidLoad()
    
    window?.title = mainWindowTitle
    
    // Reset user defaults - REMOVE LATER
//        let appDomain = Bundle.main.bundleIdentifier!
//        UserDefaults.standard.removePersistentDomain(forName: appDomain)
    
    // create SCNViews
    let headFrame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: self.parentView!.frame.size)
    headView = HeadView(frame: headFrame, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.openGLCore32.rawValue as AnyObject])
    headView!.antialiasingMode = SCNAntialiasingMode.multisampling2X
    headView!.autoresizingMask = [NSView.AutoresizingMask.height, NSView.AutoresizingMask.width]
    
    animController!.headView = headView
    
    let miniHeadFrame = CGRect(origin: CGPoint(x: 20.0, y: 20.0), size: CGSize(width: 120.0, height: 120.0))
    miniView = MiniHeadView(frame: miniHeadFrame, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.openGLCore32.rawValue as AnyObject])
    miniView!.antialiasingMode = SCNAntialiasingMode.multisampling4X
    miniView!.isHidden = false
    miniView!.headView = headView
    
    // create scene factory
    let scene = SCNScene(named: "art.scnassets/BaseMeshExport5.dae")!
    let miniScene = SCNScene(named: "art.scnassets/MiniHead.dae")!
    self.sceneFactory = SceneFactory(headScene: scene, miniScene: miniScene)
    // create morph targets
    let morphSettings: [String: AnyObject] = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "MorphTargets2", ofType: "plist")!) as! [String: AnyObject]
    sceneFactory!.createMorphTargets(morphSettings)
    
    // save scene factory
//    let sceneFactoryData: Data = NSKeyedArchiver.archivedData(withRootObject: self.sceneFactory!)
//    let panel = NSSavePanel()
//    panel.canCreateDirectories = true
//    panel.allowedFileTypes = ["plist"]
//    panel.beginSheetModal(for: self.window!) { (result) -> Void in
//      if result.rawValue == NSFileHandlingPanelOKButton {
//        if let url = panel.url {
//          do {
//            try sceneFactoryData.write(to: url)
//          } catch {
//            NSLog("Writing error: %@", error.localizedDescription)
//          }
//        }
//      }
//    }
    
    // load scene factory
//    if let sceneFactoryPath = Bundle.main.path(forResource: "Scene", ofType: "plist") {
//      if let scnFactory = NSKeyedUnarchiver.unarchiveObject(withFile: sceneFactoryPath) as? SceneFactory {
//        self.sceneFactory = scnFactory
//      } else {
//        let alert = NSAlert()
//        alert.messageText = "Unable to load scene factory!"
//        alert.runModal()
//      }
//    } else {
//      let alert = NSAlert()
//      alert.messageText = "Unable to find resource for scene factory!"
//      alert.runModal()
//    }
    
    sceneFactory!.bind(NSBindingName(rawValue: "sliceIndicatorColor"), to: userDefaultsController!, withKeyPath: "values."+slice_indicator_color_key, options: [NSBindingOption.valueTransformerName: NSValueTransformerName.unarchiveFromDataTransformerName])
    
    // create opengl shader programs
    let headProgram = SCNProgram()
    headProgram.delegate = self
    headProgram.vertexShader = getStringFromFile("clipping-doublesided", type: "vsh")
    headProgram.fragmentShader = getStringFromFile("clipping-doublesided", type: "fsh")
    // attributes
    headProgram.setSemantic(SCNGeometrySource.Semantic.vertex.rawValue, forSymbol: "in_position", options: nil)
    headProgram.setSemantic(SCNGeometrySource.Semantic.normal.rawValue, forSymbol: "in_normal", options: nil)
    headProgram.setSemantic(SCNGeometrySource.Semantic.texcoord.rawValue, forSymbol: "in_texCoord0", options: nil)
    // uniforms
    headProgram.setSemantic(SCNModelViewProjectionTransform, forSymbol: "u_modelViewProjectionTransform", options: nil)
    headProgram.setSemantic(SCNModelViewTransform, forSymbol: "u_modelViewTransform", options: nil)
    headProgram.setSemantic(SCNModelTransform, forSymbol: "u_modelTransform", options: nil)
    
    // Mini head program
    let miniHeadProgram = SCNProgram()
    miniHeadProgram.delegate = self
    miniHeadProgram.vertexShader = getStringFromFile("mini-head", type: "vsh")
    miniHeadProgram.fragmentShader = getStringFromFile("mini-head", type: "fsh")
    // attributes
    miniHeadProgram.setSemantic(SCNGeometrySource.Semantic.vertex.rawValue, forSymbol: "in_position", options: nil)
    miniHeadProgram.setSemantic(SCNGeometrySource.Semantic.normal.rawValue, forSymbol: "in_normal", options: nil)
    miniHeadProgram.setSemantic(SCNGeometrySource.Semantic.texcoord.rawValue, forSymbol: "in_texCoord0", options: nil)
    // uniforms
    miniHeadProgram.setSemantic(SCNModelViewProjectionTransform, forSymbol: "u_modelViewProjectionTransform", options: nil)
    miniHeadProgram.setSemantic(SCNModelViewTransform, forSymbol: "u_modelViewTransform", options: nil)
    miniHeadProgram.setSemantic(SCNModelTransform, forSymbol: "u_modelTransform", options: nil)
    
    // Mini head outline program
    let miniHeadOutlineProgram = SCNProgram()
    miniHeadOutlineProgram.delegate = self
    miniHeadOutlineProgram.vertexShader = getStringFromFile("mini-head-outline", type: "vsh")
    miniHeadOutlineProgram.fragmentShader = getStringFromFile("mini-head-outline", type: "fsh")
    // attributes
    miniHeadOutlineProgram.setSemantic(SCNGeometrySource.Semantic.vertex.rawValue, forSymbol: "in_position", options: nil)
    miniHeadOutlineProgram.setSemantic(SCNGeometrySource.Semantic.normal.rawValue, forSymbol: "in_normal", options: nil)
    miniHeadOutlineProgram.setSemantic(SCNGeometrySource.Semantic.texcoord.rawValue, forSymbol: "in_texCoord0", options: nil)
    // uniforms
    miniHeadOutlineProgram.setSemantic(SCNModelViewProjectionTransform, forSymbol: "u_modelViewProjectionTransform", options: nil)
    miniHeadOutlineProgram.setSemantic(SCNModelViewTransform, forSymbol: "u_modelViewTransform", options: nil)
    miniHeadOutlineProgram.setSemantic(SCNModelTransform, forSymbol: "u_modelTransform", options: nil)
    
    let programMap: [String: SCNProgram] = ["clipping-doublesided": headProgram, 
                                            "mini-head": miniHeadProgram, 
                                            "mini-head-outline": miniHeadOutlineProgram]
    
    // Head material factory
    let materialSettings = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "MaterialSettings", ofType: "plist")!) as! [String: AnyObject]
    self.materialFactory = MaterialFactory(withOpenGLContext: headView!.openGLContext!, settings: materialSettings, programs: programMap)
    materialFactory!.userDefaultsController = userDefaultsController
    materialFactory!.delegate = self
    materialFactory!.bind(NSBindingName(rawValue: "lightSlider"),
                          to: userDefaultsController!,
                          withKeyPath: "values."+lighting_slider_key,
                          options: nil)
    materialFactory!.initNodeTree(sceneFactory!.scene.rootNode)
    
    // Mini head material factory
    let miniMaterialSettings = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "MiniMaterialSettings", ofType: "plist")!) as! [String: AnyObject]
    self.miniMaterialFactory = MiniMaterialFactory(withOpenGLContext: miniView!.openGLContext!, settings: miniMaterialSettings, programs: programMap)
    miniMaterialFactory!.userDefaultsController = userDefaultsController
    miniMaterialFactory!.delegate = self
    miniMaterialFactory!.ambientColor = vector_float3(3.0, 3.0, 3.0)
    miniMaterialFactory!.initNodeTree(sceneFactory!.miniScene.rootNode)
    
    // create animation factory
    let phoneSettings: [String: AnyObject] = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Phones2", ofType: "plist")!) as! [String: AnyObject]
    let timeSettings: [String: NSNumber] = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Timing2", ofType: "plist")!) as! [String: NSNumber]
    self.animFactory = AnimationFactory(phones: phoneSettings, times: timeSettings, headTargetMap: sceneFactory!.morphTargetMap!)
  
    // load animation factory plist
//    if let animFactoryPath = Bundle.main.path(forResource: "Animation", ofType: "plist") {
//      if let factory = NSKeyedUnarchiver.unarchiveObject(withFile: animFactoryPath) as? AnimationFactory {
//        self.animFactory = factory
//      } else {
//        NSLog("Unable to load anim factory!")
//      }
//    } else {
//      NSLog("Unable to find resource for anim factory!")
//    }
    
    // load animation factory xml
    if let animFactoryPath = Bundle.main.path(forResource: "Animation", ofType: "xml") {
      do {
        let documentURL = URL(fileURLWithPath: animFactoryPath)
        let document = try XMLDocument(contentsOf: documentURL, options: XMLNode.Options(rawValue: 0))
        if let root = document.rootElement() {
          if let factory = try AnimationFactory(with: root) {
            self.animFactory = factory
          }
        }
      } catch {
        let alert = NSAlert()
        alert.messageText = error.localizedDescription
        alert.runModal()
      }
    }
    
    // dependency injection
    // set the scene to the view
    headView!.scene = sceneFactory!.scene
    headView!.sceneFactory = self.sceneFactory
    headView!.materialFactory = self.materialFactory
    headView!.animController = self.animController
    
    miniView!.scene = sceneFactory!.miniScene
    miniView!.sceneFactory = self.sceneFactory
    miniView!.materialFactory = self.materialFactory
    
    // timeline!.animFactory = self.animFactory!
    textView!.animFactory = self.animFactory!
    
    animController!.sceneFactory = sceneFactory
    animController!.animFactory = animFactory
    
    // register observers
    userDefaultsController?.addObserver(headView!, forKeyPath: "values."+hair_color_key, options: [.new], context: &HeadViewKVOContext)
    userDefaultsController?.addObserver(headView!, forKeyPath: "values."+flesh_color_key, options: [.new], context: &HeadViewKVOContext)
    userDefaultsController?.addObserver(headView!, forKeyPath: "values."+teeth_color_key, options: [.new], context: &HeadViewKVOContext)
    userDefaultsController?.addObserver(headView!, forKeyPath: "values."+bone_color_key, options: [.new], context: &HeadViewKVOContext)
    userDefaultsController?.addObserver(headView!, forKeyPath: "values."+brian_color_key, options: [.new], context: &HeadViewKVOContext)
    userDefaultsController?.addObserver(headView!, forKeyPath: "values."+eye_color_key, options: [.new], context: &HeadViewKVOContext)
    
    // head?.geometry!.shaderModifiers = [SCNShaderModifierEntryPointGeometry: "gl_ClipDistance[0] = 0.0;"]
    
    // Technique
    //    if let path = NSBundle.mainBundle().pathForResource("Stencil", ofType: "plist") {
    //      if let techDict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
    //        let technique = SCNTechnique(dictionary: techDict)!
    //        self.headView.technique = technique
    //      }
    //    }
    
    // set renderer delegate
    self.headView!.delegate = self.headView!
    
    // show statistics such as fps and timing information
    self.headView!.showsStatistics = false
    self.miniView!.showsStatistics = false
        
    // init headView
    self.headView!.initScene()    
    
    // configure the view
    self.headView!.bind(NSBindingName(rawValue: "lightSlider"),
                        to: userDefaultsController!,
                        withKeyPath: "values."+lighting_slider_key, 
                        options: nil)
    
    self.headView!.bind(NSBindingName(rawValue: "brianIsVisible"),
                        to: userDefaultsController!,
                        withKeyPath: "values."+brian_visible_key, 
                        options: nil)
    
    // cursor rects
    self.window?.disableCursorRects()
    
    // create MorphWindow
    //    let morphWindowController = MorphWindowController()
    //    morphWindowController.morphTargets = headTargetList
    //    morphWindowController.scnNode = sceneFactory!.head
    //    morphWindowController.showWindow(self)
    //    self.morphWindowController = morphWindowController
    
    // create Animation Tool
//    let animToolController = AnimationToolController()
//    animToolController.sceneFactory = sceneFactory
//    animToolController.animFactory = animFactory
//    animToolController.animController = animController
//    animToolController.showWindow(self)
//    self.animToolController = animToolController
    
    // recover save file url
    if let defaults = self.userDefaultsController?.defaults {
      if let saveFileData = defaults.data(forKey: save_file_key) {
        if let url = NSKeyedUnarchiver.unarchiveObject(with: saveFileData) as? URL {
          self.animController!.saveFileURL = url
        }
      }
    }
  }
  
  func program(_ program: SCNProgram, handleError error: Error) {
    NSLog(error.localizedDescription)
  }
  
  //MARK: Material Factory Delegate
  
  func didLoadTextures() {
    parentView!.addSubview(headView!)
    // set contraints
    let constraintViews = ["head": headView!]
    let hConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: "H:|[head]|", 
      options: NSLayoutConstraint.FormatOptions(rawValue: 0), 
      metrics: nil, 
      views: constraintViews)
    parentView!.addConstraints(hConstraints)
    
    let vConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: "V:|[head]|", 
      options: NSLayoutConstraint.FormatOptions(rawValue: 0), 
      metrics: nil, 
      views: constraintViews)
    parentView!.addConstraints(vConstraints)
    
    headView!.addSubview(miniView!)
  }
  
  // MARK: Change Shader
  
  @IBAction func onHeadShader(_ sender: NSMenuItem) {
    if sender.title == "Normal" {
      self.materialFactory?.changeProgram(sceneFactory!.scene.rootNode, programName: "clipping-doublesided")
    } else if sender.title == "Outline" {
      self.materialFactory?.changeProgram(sceneFactory!.scene.rootNode, programName: "mini-head-outline")
    }
  }
  
  @IBAction func onMiniHeadShader(_ sender: NSMenuItem) {
    if sender.title == "Normal" {
      self.miniMaterialFactory?.changeProgram(sceneFactory!.miniScene.rootNode, programName: "mini-head")
    } else if sender.title == "Outline" {
      self.miniMaterialFactory?.changeProgram(sceneFactory!.miniScene.rootNode, programName: "mini-head-outline")
    }
  }
  
  // MARK: Export Image
  
  @IBAction func onImageExport(_ sender: AnyObject) {
    guard self.window!.attachedSheet == nil else {
      return
    }
    
    if imageExportController == nil {
      imageExportController = ImageExportController()
    }
    
    let panel = NSSavePanel()
    panel.accessoryView = imageExportController?.view
    panel.canCreateDirectories = true
    panel.allowedFileTypes = ["png"]
    panel.beginSheetModal(for: self.window!) { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        if let url = panel.url, let size = self.imageExportController?.exportSize {
          guard size.width > 1.0 && size.height > 1.0 else {
            let alert = NSAlert()
            alert.messageText = "Unable to create image"
            alert.informativeText = "Image resolution \(size) is to small."
            alert.runModal()
            return
          }
          guard size.width < 5000 && size.height < 5000 else {
            let alert = NSAlert()
            alert.messageText = "Unable to create image"
            alert.informativeText = "Image resolution \(size) is to big."
            alert.runModal()
            return
          }
          self.exportImage(withSize: size, toFile: url)
        }
      }
    }
  }
  
  func exportImage(withSize size: CGSize, toFile url: URL) {
    let cgImage = headView!.renderImage(withSize: size)
    do {
      try cgImage?.saveAsPNG(to: url, compression: NSNumber(value: 1.0))
    } catch {
      let alert = NSAlert(error: error)
      alert.runModal()
    }
  }
  
  //MARK: New Document
  
  @objc func newDocument(_ sender: Any) {
    switch optionUserToSave(sender) {
    case .yes:
      if let url = animController!.saveFileURL, animController!.saveIPAText(to: url) {
      } else {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedFileTypes = ["xml"]
        panel.beginSheetModal(for: self.window!) { (result) -> Void in
          if result == NSApplication.ModalResponse.OK {
            if let url = panel.url {
              if self.animController!.saveIPAText(to: url) {
                self.newDocument(self)
              }
            }
          }
        }
        return
      }
    case .no: break
    case .cancel: return
    }
    animController!.reset()
  }
  
  // MARK: Save and Load
  
  @objc func saveDocument(_ sender: Any) {
    if let url = animController!.saveFileURL {
      if let _ = animController!.fileBookmarks[url] {
        animController!.saveIPATextWithBookmark(to: url)
      } else {
        _ = animController!.saveIPAText(to: url)
      }
    } else {
      saveDocumentAs(self)
    }
  }
  
  @objc func saveDocumentAs(_ sender: Any) {
    let panel = NSSavePanel()
    panel.canCreateDirectories = true
    panel.allowedFileTypes = ["xml"]
    panel.beginSheetModal(for: self.window!) { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        if let url = panel.url {
          self.animController!.saveIPATextWithDialog(to: url)
        }
      }
    }
  }
  
  @objc func openDocument(_ sender: Any) {
    
    switch optionUserToSave(sender) {
    case .yes:
      if let url = animController!.saveFileURL, animController!.saveIPAText(to: url) {
      } else {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedFileTypes = ["xml"]
        panel.beginSheetModal(for: self.window!) { (result) -> Void in
          if result == NSApplication.ModalResponse.OK {
            if let url = panel.url {
              if self.animController!.saveIPAText(to: url) {
                self.openDocument(self)
              }
            }
          }
        }
        return
      }
    case .no: break
    case .cancel: return
    }
    
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedFileTypes = ["xml"]
    panel.beginSheetModal(for: self.window!) { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        if let url = panel.urls.first {
          self.animController!.loadIPAText(from: url)
        }
      }
    }
  }
  
  @objc func revertDocumentToSaved(_ sender: Any) {
    if let url = animController!.saveFileURL {
      let alert = NSAlert()
      alert.messageText = "Unsaved changes!"
      alert.informativeText = "Do you really want to revert to the last save?"
      alert.addButton(withTitle: "Yes")
      alert.addButton(withTitle: "No")
      if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
        self.animController!.loadIPAText(from: url)
      }
    }
  }
  
  func optionUserToSave(_ sender: Any) -> UserInput {
    if animController!.hasUnsavedChanges &&
      (animController!.textView!.phones.count > 0 ||
      animController!.audioView!.audioURL != nil) {
      let alert = NSAlert()
      alert.messageText = "Unsaved changes!"
      alert.informativeText = "Do you want to save your current project?"
      alert.addButton(withTitle: "Yes")
      alert.addButton(withTitle: "No")
      alert.addButton(withTitle: "Cancel")
      let result = alert.runModal()
      switch result {
      case NSApplication.ModalResponse.alertFirstButtonReturn:
        return .yes
      case NSApplication.ModalResponse.alertSecondButtonReturn:
        return .no
      case NSApplication.ModalResponse.alertThirdButtonReturn:
        return .cancel
      default:
        return .cancel
      }
    }
    return .no
  }
  
  @IBAction func importAudio(_ sender: NSButton) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedFileTypes = self.animController!.SUPPORTED_AV_EXTENSIONS
    panel.beginSheetModal(for: self.window!) { (result) -> Void in
      if result == NSApplication.ModalResponse.OK {
        if let url = panel.urls.first {
          self.animController!.loadAudioDirectly(from: url)
        }
      }
    }
  }
  
  @IBAction func removeAudio(_ sender: Any) {
    self.animController!.removeAudio()
  }
  
}

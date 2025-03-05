//
//  PerspectiveCollectionView.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 24.03.17.
//  Copyright © 2017 Uli Held. All rights reserved.
//

import Cocoa

fileprivate let myDraggedType = "public.item"

class PerspectiveCollectionViewController: NSViewController, NSCollectionViewDataSource {
  
  @IBOutlet weak var collectionView: NSCollectionView?
  @IBOutlet weak var animController: AnimationController?
  @IBOutlet weak var popover: NSPopover?
  
  var perspectives: SHPerspectiveCollection?
  
  @objc dynamic var editMode: Bool = false {
    didSet {
      collectionView?.reloadData()
    }
  }
  
  var maxNumberedItems = 10
  var perspectivesMenu: NSMenu?
  
  var draggingIndexPaths: Set<IndexPath> = []
  var draggingItem: NSCollectionViewItem?
  
  override var nibName: NSNib.Name? {
    return NSNib.Name("PerspectiveCollectionView")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let flowLayout = NSCollectionViewFlowLayout()
    flowLayout.itemSize = NSSize(width: 80.0, height: 100.0)
    flowLayout.sectionInset = NSEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
    flowLayout.minimumInteritemSpacing = 10.0
    flowLayout.minimumLineSpacing = 10.0
    collectionView?.collectionViewLayout = flowLayout
    
    // Register Drag and Drop
    collectionView?.delegate = self
    collectionView?.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
  }
  
  override func viewWillDisappear() {
    editMode = false
    if let undo = undoManager {
      undo.removeAllActions(withTarget: self)
    }
  }
  
  // MARK: Collection View Source
  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    return 1
  }
  
  // Number of items in section
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let perspectives = self.perspectives else {
      return 0
    }
    return perspectives.count + (editMode ? 1 : 0)
  }
  
  // Item for represented object at
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    guard let perspectiveView = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PerspectiveView"), for: indexPath) as? PerspectiveViewItem,
          let perspectives = self.perspectives else {
      return NSCollectionViewItem()
    }
    
    let arrayIndex = indexPath.item
    if arrayIndex < perspectives.count {
      let perspective = perspectives.perspectives[arrayIndex]
      if indexPath.item < maxNumberedItems {
        perspectiveView.shortcutLabel?.stringValue = String(indexPath.item + 1)
        perspectiveView.shortcutLabel?.isHidden = false
      } else {
        perspectiveView.shortcutLabel?.isHidden = true
      }
      perspectiveView.hideControls = !editMode
      perspectiveView.perspective = perspective
      perspectiveView.perspectiveController = self
      perspectiveView.imageView?.image = perspective.image
      if let name = perspective.name {
        perspectiveView.textField?.stringValue = name
        perspectiveView.textField?.isHidden = false
      } else {
        perspectiveView.textField?.stringValue = "Custom"
        perspectiveView.textField?.isHidden = false
      }
    } else {
      perspectiveView.imageView?.image = #imageLiteral(resourceName: "plus")
      perspectiveView.hideControls = true
      perspectiveView.textField?.isHidden = true
      perspectiveView.shortcutLabel?.isHidden = true
    }    
    return perspectiveView
  }
  
  // MARK: Collection View functions
  
  func replace(at index: Int, with perspective: SHPerspectiveData) {
    guard let perspectives = self.perspectives else {
      return
    }
    
    if let undo = undoManager {
      let replacePerspective = perspectives.perspectives[index] 
      undo.registerUndo(withTarget: self) {targetSelf in
        targetSelf.replace(at: index, with: replacePerspective)
      }
      if !undo.isUndoing {
        undo.setActionName("Replace")
      }
    }
    
    perspectives.perspectives[index] = perspective
  }
  
  func insertx(perspective: SHPerspectiveData, at index: Int) {
    guard let perspectives = self.perspectives else {
      return
    }

    if let undo = undoManager { 
      undo.registerUndo(withTarget: self) {targetSelf in
        targetSelf.delete(perspective: perspective)
      }
      if !undo.isUndoing {
        undo.setActionName("Insert Perspective")
      }
    }
    
    var newPerspectives = perspectives.perspectives
    newPerspectives.insert(perspective, at: index)
    perspectives.perspectives = newPerspectives
    collectionView?.reloadData()
    perspectives.updateMenuItems()
  }
  
  func append(perspective: SHPerspectiveData) {
    guard let perspectives = self.perspectives else {
      return
    }

    if let undo = undoManager {
      undo.registerUndo(withTarget: self) {targetSelf in
        targetSelf.delete(perspective: perspective)
      }
      if !undo.isUndoing {
        undo.setActionName("Add Perspective")
      }
    }
    
    var newPerspectives = perspectives.perspectives
    newPerspectives.append(perspective)
    perspectives.perspectives = newPerspectives
    
    collectionView?.reloadData()
    perspectives.updateMenuItems()
  }
  
  func delete(perspective: SHPerspectiveData) {
    guard let perspectives = self.perspectives else {
      return
    }

    if let index = perspectives.perspectives.index(of: perspective) {
      if let undo = undoManager {
        undo.registerUndo(withTarget: self) {targetSelf in
          targetSelf.insertx(perspective: perspective, at: index)
        }
        if !undo.isUndoing {
          undo.setActionName("Delete Perspective")
        }
      }
      
      var newPerspectives = perspectives.perspectives
      newPerspectives.remove(at: index)
      perspectives.perspectives = newPerspectives
      collectionView?.reloadData()
      perspectives.updateMenuItems()
    }
  }
  
  func replace(perspective: SHPerspectiveData, at index: Int) {
    guard let perspectives = self.perspectives else {
      return
    }
    
    if let undo = undoManager {
      let oldPerspective = perspectives.perspectives[index]
      undo.registerUndo(withTarget: self) {targetSelf in
        targetSelf.replace(perspective: oldPerspective, at: index)
      }
      if !undo.isUndoing {
        undo.setActionName("Replace Perspective")
      }
    }
    
    var newPerspectives = perspectives.perspectives
    newPerspectives[index] = perspective
    perspectives.perspectives = newPerspectives
    collectionView?.reloadData()
    perspectives.updateMenuItems()
  }
  
  func updateName(name: String?, perspective: SHPerspectiveData) {
    guard let perspectives = self.perspectives else {
      return
    }
    
    perspective.name = name
    perspectives.saveToDefaults()
    // collectionView?.reloadData()
    perspectives.updateMenuItems()
  }
}

extension PerspectiveCollectionViewController: NSCollectionViewDelegate {
  // Did select item at
  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    guard let perspectives = self.perspectives else {
      return
    }

    if let index = indexPaths.first {
      let arrayIndex = index.item
      if !editMode && arrayIndex < perspectives.count {
        self.animController?.perspectiveActivate(index: arrayIndex)
      } else if arrayIndex == perspectives.count {
        if let newPerspectiveData = self.animController?.headView?.perspectiveWithImage() {
          self.append(perspective: newPerspectiveData)
        }
      }
      collectionView.deselectAll(self)
    }
  }
  
  // Dragging Session will begin at
  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) 
  {
    draggingIndexPaths = indexPaths
    
    if let indexPath = draggingIndexPaths.first, let item = collectionView.item(at: indexPath) {
      draggingItem = item
    }
  }
  
  // Dragging Session ended at
  func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) 
  {
    draggingIndexPaths = []
    draggingItem = nil
  }
  
  // Can drag items at
  func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool {
    guard let index = indexes.first, let perspectives = self.perspectives else {
      return false
    }
    return editMode && index < perspectives.count 
  }
  
  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? 
  {
    guard let perspectives = self.perspectives, indexPath.item < perspectives.count else {
      return nil
    }
    
    let perspective = perspectives.perspectives[indexPath.item]
    let pb = NSPasteboardItem()
    pb.setString(perspective.name ?? "", forType: NSPasteboard.PasteboardType.string)
    return pb
  }
  
  func collectionView(_ collectionView: NSCollectionView, 
                      validateDrop draggingInfo: NSDraggingInfo, 
                      proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, 
                      dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation 
  {
    let dropOperation = proposedDropOperation.pointee as NSCollectionView.DropOperation
    let proposedDropIndexPath = proposedDropIndexPath.pointee as IndexPath
    guard let perspectives = self.perspectives, 
      dropOperation == .on && proposedDropIndexPath.item < perspectives.count else 
    {
      return .delete
    }
    
    if let draggingItem = draggingItem, 
      let currentIndexPath = collectionView.indexPath(for: draggingItem), 
      currentIndexPath != proposedDropIndexPath {
      
      collectionView.animator().moveItem(at: currentIndexPath, to: proposedDropIndexPath)
    }
    
    return .move
  }
  
  // Accept Drop
  func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool 
  {
    guard let perspectives = self.perspectives, 
      dropOperation == .on && indexPath.item < perspectives.count else 
    {
      return false
    }
    
    for fromIndexPath in draggingIndexPaths {
      if fromIndexPath.item != indexPath.item {
        var newPerspectives = perspectives.perspectives
        let temp = newPerspectives.remove(at: fromIndexPath.item)
        newPerspectives.insert(temp, at: indexPath.item)
        perspectives.perspectives = newPerspectives
        collectionView.reloadData()
        perspectives.updateMenuItems()
      }
    }
    
    return true
  }  
}

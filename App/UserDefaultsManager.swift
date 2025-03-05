//
//  UserDefaultsManager.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 02.12.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

// IPA Text
let auto_ipa_popover_key = "auto_ipa_popover_key"
let auto_adjust_preparation_duration_key = "auto_adjust_preparation_duration_key" 

let ipa_font_key = "ipa_font_key"
let text_cursor_color_key = "text_cursor_color_key"
let text_selection_color_key = "text_selection_color_key"
let primary_indicator_color_key = "primary_indicator_color_key" 
let secondary_indicator_color_key = "secondary_indicator_color_key"
let timeline_cursor_color_key = "timeline_cursor_color_key" 
let timeline_selection_color_key = "timeline_selection_color_key"
let audio_color_key = "audio_color_key"
let symbol_highlighting_color_key = "symbol_highlighting_color_key"

// Head
let model_quality_key = "model_quality_key"
let lighting_slider_key = "lighting_slider_key"
let hair_color_key = "hair_color_key"
let flesh_color_key = "flesh_color_key"
let bone_color_key = "bone_color_key"
let teeth_color_key = "teeth_color_key"
let skin_color_key = "skin_color_key"
let eye_color_key = "eye_color_key"
let eye_brow_color_key = "eye_brow_color_key"
let slice_indicator_color_key = "slice_indicator_color_key"
let brian_color_key = "brian_color_key"
let brian_visible_key = "brian_visible_key"

// Image Export
let image_export_width_key = "image_export_width_key"
let image_export_height_key = "image_export_height_key"

// App state
let custom_perspectives_key = "custom_perspectives_key"
let current_perspective_key = "current_perspective_key"
let ipa_text_key = "ipa_text_key"
let audio_file_key = "audio_file_key" 
let ipa_default_key = "ipa_default_key"
let speed_key = "speed_key"
let recent_files_key = "recent_files_key"
let files_bookmark_key = "files_bookmark_key"
let audio_bookmark_key = "audio_bookmark_key"
let save_file_key = "save_file_key"

class UserDefaultsManager {
  
  private let userDefaults = UserDefaults.standard
  
  init() {
    registerDefaultPreferences()
  }
  
  func registerDefaultPreferences() {
    // IPA text behavior
    userDefaults.register(defaults: 
      [auto_ipa_popover_key: true,
       auto_adjust_preparation_duration_key: true])
    
    // IPA text font
    let defaultFontData = NSKeyedArchiver.archivedData(withRootObject: NSFont.systemFont(ofSize: 13))
    userDefaults.register(defaults: [ipa_font_key: defaultFontData])
    
    // IPA text colors
    let textCursorColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.black)
    userDefaults.register(defaults: [text_cursor_color_key: textCursorColor])
    
    let textSelectionColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.selectedTextBackgroundColor)
    userDefaults.register(defaults: [text_selection_color_key: textSelectionColor])
    
    let primaryIndicatorColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.black)
    userDefaults.register(defaults: [primary_indicator_color_key: primaryIndicatorColor])
    
    let secondaryIndicatorColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.gray)
    userDefaults.register(defaults: [secondary_indicator_color_key: secondaryIndicatorColor])
    
    let timelineCursorColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.black)
    userDefaults.register(defaults: [timeline_cursor_color_key: timelineCursorColor])
    
    let timelineSelectionColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.selectedTextBackgroundColor)
    userDefaults.register(defaults: [timeline_selection_color_key: timelineSelectionColor])
    
    let audioColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.lightGray)
    userDefaults.register(defaults: [audio_color_key: audioColor])
    
    let symbolHighlightingColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.selectedControlColor)
    userDefaults.register(defaults: [symbol_highlighting_color_key: symbolHighlightingColor])
    
    // Head graphics
    userDefaults.register(defaults: [model_quality_key: NSNumber(value: ModelQuality.low.rawValue),
                                     lighting_slider_key: NSNumber(value: 0.5)])
    
    // Head colors
    let hairColor = NSKeyedArchiver.archivedData(withRootObject: NSColor(calibratedRed: 0.235, green: 0.341, blue: 0.427, alpha: 1))
    userDefaults.register(defaults: [hair_color_key: hairColor])
    
    let fleshColor = NSKeyedArchiver.archivedData(withRootObject: NSColor(calibratedRed: 0.537, green: 0, blue: 0.102, alpha: 1))
    userDefaults.register(defaults: [flesh_color_key: fleshColor])
    
    let boneColor = NSKeyedArchiver.archivedData(withRootObject: NSColor(calibratedRed: 0.706, green: 0.706, blue: 0.71, alpha: 1))
    userDefaults.register(defaults: [bone_color_key: boneColor])
    
    let teethColor = NSKeyedArchiver.archivedData(withRootObject: NSColor(calibratedRed: 0.404, green: 0.408, blue: 0.196, alpha: 1))
    userDefaults.register(defaults: [teeth_color_key: teethColor])
    
    let skinColor = NSKeyedArchiver.archivedData(withRootObject: NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.5, alpha: 1.0))
    userDefaults.register(defaults: [skin_color_key: skinColor])
    
    let eyeColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.brown)
    userDefaults.register(defaults: [eye_color_key: eyeColor])
    
    let eyeBrowColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.black)
    userDefaults.register(defaults: [eye_brow_color_key: eyeBrowColor])
    
    let sliceIndicatorColor = NSKeyedArchiver.archivedData(withRootObject: NSColor.red)
    userDefaults.register(defaults: [slice_indicator_color_key: sliceIndicatorColor])
    
    let brianColor = NSKeyedArchiver.archivedData(withRootObject: NSColor(calibratedRed: 0.706, green: 0.706, blue: 0.71, alpha: 1))
    userDefaults.register(defaults: [brian_color_key: brianColor,
                                     brian_visible_key: false])
    
    // Image Export
    userDefaults.register(defaults: [image_export_width_key: NSNumber(value: 1024),
                                     image_export_height_key: NSNumber(value: 1024)])
    
    // App state
    let customPerspectives = NSKeyedArchiver.archivedData(withRootObject: [SHPerspectiveData]())
    userDefaults.register(defaults: [custom_perspectives_key: customPerspectives])
    
    let currentPerspective = NSKeyedArchiver.archivedData(withRootObject: SHPerspectiveData())
    userDefaults.register(defaults: [current_perspective_key: currentPerspective])
    
    userDefaults.register(defaults: [speed_key: NSNumber(value: 1.0)])
    
    let ipaText = NSKeyedArchiver.archivedData(withRootObject: IPAText())
    userDefaults.register(defaults: [ipa_text_key: ipaText])
        
    let defaultPhone = NSKeyedArchiver.archivedData(withRootObject: Phone())
    userDefaults.register(defaults: [ipa_default_key: defaultPhone])
    
    let files = NSKeyedArchiver.archivedData(withRootObject: [URL]())
    userDefaults.register(defaults: [recent_files_key: files])
    
    let bookmarks = NSKeyedArchiver.archivedData(withRootObject: [URL: Data]())
    userDefaults.register(defaults: [files_bookmark_key: bookmarks])
    
    let audioBookmarks = NSKeyedArchiver.archivedData(withRootObject: [URL: Data]())
    userDefaults.register(defaults: [audio_bookmark_key: audioBookmarks])
    
    userDefaults.register(defaults: [save_file_key: Data()])
  }
}

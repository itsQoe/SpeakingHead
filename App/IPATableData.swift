//
//  IPATableData.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 29.06.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import AppKit

struct IPASymbols {
  let left: String
  let right: String
}

class IPATableData: NSObject, NSTableViewDataSource {
  var firstColumnName: String!
  var columnNames: [String]!
  var rowNames: [String]!
  var data: [String: [String: IPASymbols]]!
  
  override init() {
    firstColumnName = ""
    columnNames = [String]()
    rowNames = [String]()
    data = [String: [String: IPASymbols]]()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.rowNames.count
  }
  
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    if let tableColumn = tableColumn, let column = self.data[tableColumn.title] {
      if let object = column[self.rowNames[row]] {
        return object
      }
    } else if tableColumn!.title == self.firstColumnName {
      return self.rowNames[row]
    }
    return nil
  }
}

class ConsonantTableData: IPATableData {
  
  override init() {
    super.init()
    firstColumnName = "Consonants"
    columnNames = ["Bilabial", "Labiodental", "Dental", "Alveolar", "Postalveolar", "Palatal", "Velar", "Uvular", "Pharyngeal", "Glottal"]
    rowNames = ["Plosive", "Nasal", "Trill", "Flap", "Fricative", "Lateral Fricative", "Approximant", "Lateral Approximant"]
    data = ["Bilabial" : [
      "Plosive" : IPASymbols(left: "p", right: "b"),
      "Nasal" : IPASymbols(left: "", right: "m"),
      "Trill" : IPASymbols(left: "", right: "ʙ"),
      "Fricative" : IPASymbols(left: "ɸ", right: "β")
      ], "Labiodental" : [
      "Nasal" : IPASymbols(left: "", right: "ɱ"),
      "Flap" : IPASymbols(left: "", right: "ⱱ"),
      "Fricative" : IPASymbols(left: "f", right: "v"),
      "Approximant" : IPASymbols(left: "", right: "ʋ")
      ], "Dental" : [
      "Fricative" : IPASymbols(left: "θ", right: "ð")
      ], "Alveolar" : [
      "Plosive" : IPASymbols(left: "t", right: "d"),
      "Nasal" : IPASymbols(left: "", right: "n"),
      "Trill" : IPASymbols(left: "", right: "r"),
      "Flap" : IPASymbols(left: "", right: "ɾ"),
      "Fricative" : IPASymbols(left: "s", right: "z"),
      "Lateral Fricative" : IPASymbols(left: "ɬ", right: "ɮ"),
      "Approximant" : IPASymbols(left: "", right: "ɹ"),
      "Lateral Approximant" : IPASymbols(left: "", right: "l")
      ], "Postalveolar" : [
      "Fricative" : IPASymbols(left: "ʃ", right: "ʒ")
      ], "Retroflex" : [
      "Plosive" : IPASymbols(left: "ʈ", right: "ɖ"),
      "Nasal" : IPASymbols(left: "", right: "ɳ"),
      "Flap" : IPASymbols(left: "", right: "ɽ"),
      "Fricative" : IPASymbols(left: "ʂ", right: "ʐ"),
      "Approximant" : IPASymbols(left: "", right: "ɻ"),
      "Lateral Approximant" : IPASymbols(left: "", right: "ɭ")
      ], "Palatal" : [
      "Plosive" : IPASymbols(left: "c", right: "ɟ"),
      "Nasal" : IPASymbols(left: "", right: "ɲ"),
      "Fricative" : IPASymbols(left: "ç", right: "ʝ"),
      "Approximant" : IPASymbols(left: "", right: "j"),
      "Lateral Approximant" : IPASymbols(left: "", right: "ʎ")
      ], "Velar" : [
      "Plosive" : IPASymbols(left: "k", right: "g"),
      "Nasal" : IPASymbols(left: "", right: "ŋ"),
      "Fricative" : IPASymbols(left: "x", right: "ɣ"),
      "Approximant" : IPASymbols(left: "", right: "ɰ"),
      "Lateral Approximant" : IPASymbols(left: "", right: "ʟ")
      ], "Uvular" : [
      "Plosive" : IPASymbols(left: "q", right: "ɢ"),
      "Nasal" : IPASymbols(left: "", right: "ɴ"),
      "Trill" : IPASymbols(left: "", right: "ʀ"),
      "Fricative" : IPASymbols(left: "χ", right: "ʁ")
      ], "Pharyngeal" : [
      "Fricative" : IPASymbols(left: "ħ", right: "ʕ")
      ], "Glottal" : [
      "Plosive" : IPASymbols(left: "ʔ", right: ""),
      "Fricative" : IPASymbols(left: "h", right: "ɦ")
      ]
    ]
  }  
}

class VowelTableData: IPATableData {
  
  override init() {
    super.init()
    firstColumnName = "Vowels"
    columnNames = ["Front", "Near-Front", "Central", "Near-Back", "Back"]
    rowNames = ["Close", "Near-Close", "Close-Mid", "Mid", "Open-Mid", "Near-Open", "Open"]
    data = ["Front" : [
        "Close" : IPASymbols(left: "i", right: "y"),
        "Close-Mid" : IPASymbols(left: "e", right: "ø"),
        "Open-Mid" : IPASymbols(left: "ɛ", right: "œ"),
        "Near-Open" : IPASymbols(left: "æ", right: ""),
        "Open" : IPASymbols(left: "a", right: "ɶ")
      ], "Near-Front" : [
        "Near-Close" : IPASymbols(left: "ɪ", right: "ʏ")
      ], "Central" : [
        "Close" : IPASymbols(left: "ɨ", right: "ʉ"),
        "Close-Mid" : IPASymbols(left: "ɘ", right: "ɵ"),
        "Mid" : IPASymbols(left: "ə", right: ""),
        "Open-Mid" : IPASymbols(left: "ɜ", right: "ɞ"),
        "Near-Open" : IPASymbols(left: "ɐ", right: ""),
      ], "Near-Back" : [
        "Near-Close" : IPASymbols(left: "", right: "ʊ")
      ], "Back" : [
        "Close" : IPASymbols(left: "ɯ", right: "u"),
        "Close-Mid" : IPASymbols(left: "ɤ", right: "o"),
        "Open-Mid" : IPASymbols(left: "ʌ", right: "ɔ"),
        "Open" : IPASymbols(left: "ɑ", right: "ɒ")
      ]
    ]
  }
}

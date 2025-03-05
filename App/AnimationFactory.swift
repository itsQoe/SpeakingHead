//
//  AnimationFactory.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 02.02.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import SceneKit

fileprivate let phone_dict_key = "phone_dict"
fileprivate let phone_anim_dict_key = "phone_anim_dict"
fileprivate let time_dict_key = "time_dict"
fileprivate let head_path_dict_key = "head_path_dict"

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class AnimationFactory: NSObject, NSCoding, XMLCoding {
  var phoneDict: [String: Phone]
  var phoneAnimDict: [String: PhoneAnimation]
  var timeDict: [String: Float]
  var headPathDict: [String: String]
  var limitWithMouth: [String] = ["tongue-open", "tongue-front-open"]
  
  var defaultEndDuration: Float = 0.15
  
  var reducePrimaryMovement: Bool = true
  var reduceSecondaryMovement: Bool = true
  var reduceBoundLower: Float = 0.2
  var reduceBoundUpper: Float = 0.2
  
  // MARK: Init
  convenience init(phones phonesPList: [String: AnyObject], times timesPList: [String: NSNumber], headTargetMap: [String: String]) {
    var phoneDict = [String: Phone]()
    var myAnimDict = [String: PhoneAnimation]()
    
    for phoneKV in phonesPList {
      let valueDict = phoneKV.1 as! [String: NSObject]
      let phone: Phone = Phone()
      let phoneAnim = PhoneAnimation()
      phone.symbol = phoneKV.0
      phoneAnim.symbol = phoneKV.0
      phone.mode = valueDict["mode"] as? String ?? ""
      let animDict = valueDict["Animation"] as! [String: NSObject]
      
      for animKV in animDict {
        let animValueDict = animKV.1 as! [String: NSObject]
        let animPart = animValueDict["part"] as? String ?? ""
        let targetStr = animValueDict["target"] as! String        
        let animKey = AnimKey(part: animPart,
                              target: targetStr,
                              min: animValueDict["min"] as? Float ?? 0.0,
                              max: animValueDict["max"] as? Float ?? 0.0,
                              rep: animValueDict["repeat"] as? Int ?? 0)
        
        
        switch animValueDict["phase"] as! String {
        case "preparation": phoneAnim.prepAnimation.append(animKey)
        case "secondary": phoneAnim.secAnimation.append(animKey)
        case "articulation": phoneAnim.artAnimation.append(animKey)
        default: break
        }
      }
      phoneDict[phone.symbol] = phone
      myAnimDict[phone.symbol] = phoneAnim
    }
    
    let times: [String: Float] = timesPList.mapValues({(number: NSNumber) -> Float in number.floatValue})
    self.init(phones: phoneDict, phoneAnims: myAnimDict,
              times: times, headPaths: headTargetMap)
  }
  
  init(phones: [String: Phone], phoneAnims: [String: PhoneAnimation],
       times: [String: Float], headPaths: [String: String])
  {
    phoneDict = phones
    phoneAnimDict = phoneAnims
    timeDict = times
    headPathDict = headPaths
  }
  
  required init?(coder: NSCoder) {
    self.phoneDict = coder.decodeObject(forKey: phone_dict_key) as? [String: Phone] ?? [String: Phone]()
    self.phoneAnimDict = coder.decodeObject(forKey: phone_anim_dict_key) as? [String: PhoneAnimation] ?? [String: PhoneAnimation]()
    self.timeDict = coder.decodeObject(forKey: time_dict_key) as? [String: Float] ?? [String: Float]()
    self.headPathDict = coder.decodeObject(forKey: head_path_dict_key) as? [String: String] ?? [String: String]() 
    
    super.init()
  }
  
  required init?(with node: XMLNode) throws {
    self.phoneDict = [String: Phone]()
    self.phoneAnimDict = [String: PhoneAnimation]()
    self.timeDict = [String: Float]()
    self.headPathDict = [String: String]()
    super.init()
    
    guard let node = node as? XMLElement else {
      throw IPATextError(kind: .xmlParsingError)
    }
    
    if let phonesNode = node.elements(forName: phone_dict_key).first {
      self.phoneDict = try XMLHelper.decodeDict(node: phonesNode)
    }
    if let phoneAnimNode = node.elements(forName: phone_anim_dict_key).first {
      self.phoneAnimDict = try XMLHelper.decodeDict(node: phoneAnimNode)
    }
    if let timeNode = node.elements(forName: time_dict_key).first {
      self.timeDict = XMLHelper.decodeStringDict(node: timeNode)
    }
    if let headPathNode = node.elements(forName: head_path_dict_key).first {
      self.headPathDict = XMLHelper.decodeStringDict(node: headPathNode)
    }
  }
  
  func encode(with coder: NSCoder) {
    coder.encode(self.phoneDict, forKey: phone_dict_key)
    coder.encode(self.phoneAnimDict, forKey: phone_anim_dict_key)
    coder.encode(self.timeDict, forKey: time_dict_key)
    coder.encode(self.headPathDict, forKey: head_path_dict_key)
  }
  
  func encodeXML(withKey key: String) -> XMLNode {
    let root = XMLElement(name: key)
    root.addChild(XMLHelper.encodeDict(dict: self.phoneDict, key: phone_dict_key))
    root.addChild(XMLHelper.encodeDict(dict: self.phoneAnimDict, key: phone_anim_dict_key))
    root.addChild(XMLHelper.encodeStringDict(dict: self.timeDict, key: time_dict_key))
    root.addChild(XMLHelper.encodeStringDict(dict: self.headPathDict, key: head_path_dict_key))
    return root
  }
  
  func getPhone(_ char: String, lastPhone last: Phone?, defaultPhone: Phone?) throws -> Phone {
    if let phone: Phone = phoneDict[char]?.copy() as? Phone {
      if let def = defaultPhone {
        phone.articulation = def.articulation
        phone.art_duration = def.art_duration
        phone.prep_duration = def.prep_duration
        phone.sec_duration = def.sec_duration
      }
      return phone
    } else {
      throw IPAError.notAnIPACharacter(char: char)
    }
  }
  
  func setPhone(_ phone: Phone) {
    phoneDict[phone.ipaString] = phone
  }
  
  func getDuration(forTarget target: String, fromValue from: Float, toValue to: Float) -> Float {
    return (timeDict[target] ?? 0.0) * abs(to - from)
  }
  
  func getAnimation(forPhones phones: [Phone]) -> HeadAnimation {
    var headAnimArray = [CAAnimation]()
    
    var valueDict = [String: [Float]]()
    var timeDict = [String: [Float]]()
    var time: Float = 0.0
    
    for phone in phones {
      guard let animPhone = phoneAnimDict[phone.symbol] else {
        let alert = NSAlert()
        alert.messageText = "Unable to find animations for phone \(phone.symbol)"
        alert.runModal()
        continue
      }
      
      var mouthOpen: Float = 0.0
      var dontReverse = [String]()
      
      for animKey in animPhone.prepAnimation {
        let lastValue = valueDict[animKey.target]?.last ?? 0.0
        var value = phone.getArticulationValue(animKey.minValue, max: animKey.maxValue)
        if reducePrimaryMovement && animKey.isInRange(lastValue)
          && (lastValue - reduceBoundLower ..< lastValue + reduceBoundUpper).contains(value) {
          value = lastValue
        }
        if animKey.target == "mouth-open" {
          mouthOpen = value
        }
        var valueAddList = [Float]()
        var timeAddList = [Float]()
        valueAddList = [lastValue, value]
        timeAddList = [time, time+phone.prep_duration]
        
        if valueDict[animKey.target] == nil {
          valueDict[animKey.target] = valueAddList
          timeDict[animKey.target] = timeAddList
        } else {
          valueDict[animKey.target]?.append(contentsOf: valueAddList)
          timeDict[animKey.target]?.append(contentsOf: timeAddList)
        }
        dontReverse.append(animKey.target)
      }
      for animKey in animPhone.secAnimation {
        let lastValue = valueDict[animKey.target]?.last ?? 0.0
        var value = phone.getArticulationValue(animKey.minValue, max: animKey.maxValue)
        if reduceSecondaryMovement && animKey.isInRange(lastValue)
          && (lastValue - reduceBoundLower ..< lastValue + reduceBoundUpper).contains(value) {
          value = lastValue
        }
        if animKey.target == "mouth-open" {
          mouthOpen = value
        }

        var valueAddList = [Float]()
        var timeAddList = [Float]()
        valueAddList = [lastValue, value]
        timeAddList = [time, time+phone.sec_duration]
        
        if valueDict[animKey.target] == nil {
          valueDict[animKey.target] = valueAddList
          timeDict[animKey.target] = timeAddList
        } else {
          valueDict[animKey.target]?.append(contentsOf: valueAddList)
          timeDict[animKey.target]?.append(contentsOf: timeAddList)
        }
        dontReverse.append(animKey.target)
      }
      
      
      // Reverse
      for kv in valueDict {
        if !dontReverse.contains(kv.0) {
          if let lastValue = kv.1.last , lastValue > 0.0 {
            let duration = phone.sec_duration
            valueDict[kv.0]!.append(contentsOf: [lastValue, 0.0])
            timeDict[kv.0]!.append(contentsOf: [time, time+duration])
          }
        }
        if limitWithMouth.contains(kv.key) {
          if let lastValue = kv.value.last, lastValue > mouthOpen {
            valueDict[kv.0]?[kv.value.count-1] = mouthOpen
          }
        }
      }
      
      time += phone.prep_duration
      
      // Articulation
      for animKey in animPhone.artAnimation {
        let lastValue = valueDict[animKey.target]?.last ?? 0.0
        let value = phone.getArticulationValue(animKey.minValue, max: animKey.maxValue)
        var duration = getDuration(forTarget: animKey.target, fromValue: lastValue, toValue: value)
        var startTime = time
        
        if phone.mode == "plosive" {
          duration /= 2
          startTime = time + phone.art_duration - duration
        } else if phone.mode == "trill" {
          duration *= 2
        }
        
        if valueDict[animKey.target] == nil {
          valueDict[animKey.target] = [lastValue, value]
          timeDict[animKey.target] = [startTime, startTime+duration]
        } else {
          valueDict[animKey.target]?.append(contentsOf: [lastValue, value])
          timeDict[animKey.target]?.append(contentsOf: [startTime, startTime+duration])
        }
        
        if animKey.repeat_min > 0 {
          var rep: Int = Int(floor(phone.art_duration / (duration * 2)))
          if rep < animKey.repeat_min {
            rep = animKey.repeat_min
            duration = phone.art_duration / Float(rep * 2)
          }
          var valueList = [Float]()
          var timeList = [Float]()
          var repTime = time+duration
          for i in 2...rep*2 {
            if i % 2 == 0 {
              valueList.append(lastValue)
            } else {
              valueList.append(value)
            }
            timeList.append(repTime+duration)
            repTime += duration
          }
          valueDict[animKey.target]?.append(contentsOf: valueList)
          timeDict[animKey.target]?.append(contentsOf: timeList)
        }
      }
      time += phone.art_duration
    }
    
    // End Reverse
    for kv in valueDict {
      if let lastValue = kv.1.last {
        if lastValue > 0.0 {
          valueDict[kv.0]!.append(contentsOf: [lastValue, 0.0])
          timeDict[kv.0]!.append(contentsOf: [time, time+defaultEndDuration])
        } else {
          valueDict[kv.0]!.append(0.0)
          timeDict[kv.0]!.append(time+defaultEndDuration)
        }
      }
    }
    time += defaultEndDuration
    
    for kv in valueDict {
      let values: [Float] = kv.1
      let times: [Float] = timeDict[kv.0]!
      
      let path: String? = headPathDict[kv.0]
      if path != nil {      
        let anim = CAKeyframeAnimation(keyPath: path!)
        anim.values = values
        anim.keyTimes = times as [NSNumber]?
        
        var timingFunctions = [CAMediaTimingFunction]()
        var lastValue: Float?
        var slope1: Int?
        var slope2: Int?
        for value in values {
          var slope0: Int?
          if lastValue != nil {
            let diff = value - lastValue!
            if diff == 0 {
              slope0 = 0
            } else if value > lastValue {
              slope0 = 1
            } else if value < lastValue {
              slope0 = -1
            }
            
            if slope1 != nil && slope2 != nil {
              if slope2! == slope1! && slope1! == slope0 {
                timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
              } else if slope2! != slope1! && slope1! == slope0 {
                timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
              } else if slope2! == slope1! && slope1! != slope0 {
                timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
              } else {
                timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
              }
            }
          }
          slope2 = slope1
          slope1 = slope0
          lastValue = value
        }
        
        if slope1 == slope2 {
          timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
        } else {
          timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
        
        anim.timingFunctions = timingFunctions
        anim.duration = CFTimeInterval(time)
        headAnimArray.append(anim)
      } else {
        let alert = NSAlert()
        alert.messageText = "ERROR: Morph target \(kv.0) not found!"
        alert.runModal()
      }
    }
    
    let headAnimGroup = CAAnimationGroup()
    headAnimGroup.duration = CFTimeInterval(time)
    headAnimGroup.animations = headAnimArray
    
    return HeadAnimation(headAnimation: headAnimGroup)
  }
  
  func getPose(forCharacter char: Character) -> [String: CAAnimationGroup]? {
    var animDict = [String: [CAAnimation]]()
    animDict["head"] = [CAAnimation]()
    animDict["jaw"] = [CAAnimation]()
    var valueDict = [String: [String: Float]]()
    valueDict["head"] = [String: Float]()
    valueDict["jaw"] = [String: Float]()
    
    var time: Float = 0.0
    let phone = phoneDict[String(char)]
    let phoneAnim = phoneAnimDict[String(char)]
    phone?.articulation = 1.0
    
    if phone == nil {
      let alert = NSAlert()
      alert.messageText = "Data for character '\(String(char)))' not found."
      alert.runModal()
      return nil
    }
    
    for animKey in phoneAnim!.prepAnimation {
      let path: String = headPathDict[animKey.target]! 
      if valueDict[animKey.part]![path] == nil {
        valueDict[animKey.part]![path] = 0.0
      }
      valueDict[animKey.part]![path]! = phone!.getArticulationValue(animKey.minValue, max: animKey.maxValue) 
    }
    time += phone!.prep_duration
    
    // Create Animations
    for partDict in valueDict {
      for pathDict in partDict.1 {
        let value = pathDict.1
        let anim = CABasicAnimation(keyPath: pathDict.0)
        anim.toValue = value
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        anim.duration = CFTimeInterval(time)
        
        animDict[partDict.0]!.append(anim)
      }
    }
    
    let headAnimGroup = CAAnimationGroup()
    headAnimGroup.fillMode = kCAFillModeForwards
    headAnimGroup.isRemovedOnCompletion = false
    headAnimGroup.duration = CFTimeInterval(time)
    headAnimGroup.animations = animDict["head"]
    let jawAnimGroup = CAAnimationGroup()
    jawAnimGroup.fillMode = kCAFillModeForwards
    jawAnimGroup.isRemovedOnCompletion = false
    jawAnimGroup.duration = CFTimeInterval(time)
    jawAnimGroup.animations = animDict["jaw"]
    
    return ["head": headAnimGroup, "jaw": jawAnimGroup]
  }
}

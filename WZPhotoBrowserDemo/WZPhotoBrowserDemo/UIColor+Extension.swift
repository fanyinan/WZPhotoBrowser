//
//  MuColor.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/4/9.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit

extension UIColor {
  
  /**
  通过RGB得到颜色
  
  - parameter stringToConvert: 六位到八位的RGB字符串
  
  - returns: 颜色
  */
  class func hexStringToColor(_ stringToConvert : String, alpha: CGFloat = 1) -> UIColor{
    var cString : String = stringToConvert.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    // String should be 6 or 8 characters
    
    if cString.characters.count < 6 {
      return UIColor.black
    }
    
    if cString.hasPrefix("0X"){
      cString = NSString(string: cString).substring(from: 2)
    }
    if cString.hasPrefix("#"){
      cString = NSString(string: cString).substring(from: 1)
    }
    if cString.characters.count != 6{
      return UIColor.black
    }
    // Separate into r, g, b substrings
    var range  = NSRange(location: 0,length: 2)
    let rString = NSString(string: cString).substring(with: range)
    range.location = 2
    let gString = NSString(string: cString).substring(with: range)
    range.location = 4
    let bString = NSString(string: cString).substring(with: range)
    
    // Scan values
    var r, g, b : UInt32?
    r = 0
    g = 0
    b = 0
    Scanner(string: rString).scanHexInt32(&r!)
    Scanner(string: gString).scanHexInt32(&g!)
    Scanner(string: bString).scanHexInt32(&b!)
    
    return UIColor(red: (CGFloat(r!))/255.0, green: (CGFloat(g!))/255.0, blue: (CGFloat(b!))/255.0, alpha: alpha)
  }
  
}

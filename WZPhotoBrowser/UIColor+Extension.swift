//
//  MuColor.swift
//  MuMu
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
  class func hexStringToColor(stringToConvert : String, alpha: CGFloat = 1) -> UIColor{
    var cString : String = stringToConvert.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
    // String should be 6 or 8 characters
    
    if cString.characters.count < 6 {
      return UIColor.blackColor()
    }
    
    if cString.hasPrefix("0X"){
      cString = NSString(string: cString).substringFromIndex(2)
    }
    if cString.hasPrefix("#"){
      cString = NSString(string: cString).substringFromIndex(1)
    }
    if cString.characters.count != 6{
      return UIColor.blackColor()
    }
    // Separate into r, g, b substrings
    var range  = NSRange(location: 0,length: 2)
    let rString = NSString(string: cString).substringWithRange(range)
    range.location = 2
    let gString = NSString(string: cString).substringWithRange(range)
    range.location = 4
    let bString = NSString(string: cString).substringWithRange(range)
    
    // Scan values
    var r, g, b : UInt32?
    r = 0
    g = 0
    b = 0
    NSScanner(string: rString).scanHexInt(&r!)
    NSScanner(string: gString).scanHexInt(&g!)
    NSScanner(string: bString).scanHexInt(&b!)
    
    return UIColor(red: (CGFloat(r!))/255.0, green: (CGFloat(g!))/255.0, blue: (CGFloat(b!))/255.0, alpha: alpha)
  }
  
}

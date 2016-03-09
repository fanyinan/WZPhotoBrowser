//
//  MuString.swift
//  MuMu
//
//  Created by 范祎楠 on 15/4/6.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import Foundation

extension String{
  
  //转换为NSString
  func toNSString() -> NSString{
    return self as NSString
  }
  
  
  //获取子字符串在原字符串的位置
  func indexOfString(str:String) -> Int{
    return self.toNSString().rangeOfString(str).location
  }
  
  
  /**
   得到某个字符串后面的字符串，若没找到返回本身
   
   - parameter str: 标志字符串
   
   - returns: 截得字符串
   */
  func subStringAfter(str: String) -> String{
    let index = self.indexOfString(str)
    if index != NSNotFound{
      return self.toNSString().substringFromIndex(index + str.characters.count)
    } else {
      return self
    }
  }
  
  
  func getImageUrlWithSize(size: CGSize, imageStyle: NetImageStyle = .Cut) -> String {
    
    var width = size.width
    var height = size.height
    
    let deviceIdentifier = MuTools.deviceIdentifier()
    let identifierNum = deviceIdentifier.subStringAfter("iphone")
    
    if identifierNum != "4,1" {  //不是iphone4s
      if identifierNum == "7,1" {  //是iphone
        width *= CGFloat(3)
        height *= CGFloat(3)
      } else {   //默认其余为iPhone5 5c 5s
        width *= CGFloat(2)
        height *= CGFloat(2)
      }
    }
    
    //阿里云图片后缀
    
    var sizeSuffix = ""
    switch imageStyle {
    case .Cut:
      sizeSuffix = "@1e_\(Int(width))w_\(Int(height))h_1c_0i_1o_90Q_1x.png"
    case .OriginScale:
      sizeSuffix = "@1e_\(Int(width))w_\(Int(height))h_0c_0i_1o_90Q_1x.png"
      
    }
    
    let newUrl = self + sizeSuffix
    print("url \(newUrl)")
    return newUrl
  }
}

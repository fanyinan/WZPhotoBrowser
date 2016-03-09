//
//  MuView.swift
//  MuMu
//
//  Created by 范祎楠 on 15/4/11.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit

enum ShadowStyle{
  case Down
}

enum ViewStatus {
  case NetError //网络异常
  case DataEmpty //数据为空
  case Custom //自定义文字
  case Blank //空白
  case None //移除该view ，返回nil，其他枚举返回UIControl
}

extension UIView {
 
  
  /**
  设置圆角
  
  - parameter radius: 圆角半径，为空时，按计算height/2计算，宽高相等时为圆形
  */
  func setViewCornerRadius(var radius : CGFloat? = nil){
    if radius == nil{
      radius = self.frame.size.height / 2
    }
    self.layer.cornerRadius = radius!
    self.layer.masksToBounds = true
  }

}
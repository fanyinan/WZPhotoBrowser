//
//  CGContextTestView.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/3.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class LoadImageProgressView: UIView {
  var progress: CGFloat = 0 {
    didSet{      
      if progress >= 1.0 {
        hidden = true
      } else {
        hidden = false
        setNeedsDisplay()
      }
    }
  }
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    initView()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initView()
    
  }
  
  func initView() {
    layer.cornerRadius = 5
    clipsToBounds = true
    backgroundColor = UIColor.clearColor()
  }
  
  func dismiss() {
    progress = 1.0
    hidden = true
  }
  
  override func drawRect(rect: CGRect) {
    let ctx = UIGraphicsGetCurrentContext()!
    
    let xCenter = rect.size.width / 2
    let yCenter = rect.size.height / 2
    
    let radius = min(xCenter, yCenter) / 2
    
    let lineWidth = rect.size.width / 2
    
    UIColor.hexStringToColor("111111", alpha: 0.6).set()
    CGContextSetLineWidth(ctx, lineWidth)
    CGContextAddArc(ctx, xCenter, yCenter, radius + lineWidth / 2 + 5, CGFloat(0), CGFloat(M_PI * 2), Int32(1))
    
    CGContextStrokePath(ctx)
    
    UIColor.hexStringToColor("111111", alpha: 0.3).set()
    
    CGContextSetLineWidth(ctx, 1)
    CGContextMoveToPoint(ctx, xCenter, yCenter)
    
    let from = -CGFloat(M_PI) / 2 + progress * CGFloat(M_PI) * CGFloat(2)
    CGContextAddArc(ctx, xCenter, yCenter, radius, from, CGFloat(M_PI / 2 * 3), Int32(0))
    CGContextClosePath(ctx)
    CGContextFillPath(ctx)
  }
  
  
}

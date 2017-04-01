//
//  CGContextTestView.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/3.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class LoadImageProgressView: UIView {
  
  var color: UIColor!
  var progress: CGFloat = 0 {
    didSet{
      if progress >= 1.0 {
        isHidden = true
      } else {
        isHidden = false
        setNeedsDisplay()
      }
    }
  }
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupUI()
    setBlackStyle()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    setupUI()
    
  }
  
  func setupUI() {
    layer.cornerRadius = 5
    clipsToBounds = true
    backgroundColor = UIColor.clear
  }
  
  func dismiss() {
    progress = 1.0
    isHidden = true
  }
  
  func setWhiteStyle() {
    color = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 0.6)
    setNeedsDisplay()
  }
  
  func setBlackStyle() {
    color = UIColor(red: 17.0/255.0, green: 17.0/255.0, blue: 17.0/255.0, alpha: 0.6)
    setNeedsDisplay()
  }
  
  override func draw(_ rect: CGRect) {
    let ctx = UIGraphicsGetCurrentContext()!
    
    let xCenter = rect.size.width / 2
    let yCenter = rect.size.height / 2
    
    let radius = min(xCenter, yCenter) / 2
    
    let lineWidth = rect.size.width / 2
    
    color.set()
    ctx.setLineWidth(lineWidth)
    ctx.addArc(center: CGPoint(x: xCenter, y: yCenter), radius: radius + lineWidth / 2 + 5, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
    ctx.strokePath()
    
    color.set()
    ctx.setLineWidth(1)
    ctx.move(to: CGPoint(x: xCenter, y: yCenter))
    
    let from = -CGFloat(Double.pi) / 2 + progress * CGFloat(Double.pi) * CGFloat(2)
    ctx.addArc(center: CGPoint(x: xCenter, y: yCenter), radius: radius, startAngle: from, endAngle: CGFloat(Double.pi / 2 * 3), clockwise: false)
    ctx.closePath()
    ctx.fillPath()
  }
  
  
}

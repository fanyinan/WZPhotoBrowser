//
//  ThumbCollectionViewCell.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 16/3/8.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

class ThumbCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet var thumbImageView: UIImageView!
  @IBOutlet weak var leftMarginConstraint: NSLayoutConstraint!
  @IBOutlet weak var rightMarginConstraint: NSLayoutConstraint!
  
  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = UIColor.blackColor()
    thumbImageView.setViewCornerRadius(2)
  
  }
  
  func setImageWith(imgUrl imgUrl: String) {
    thumbImageView.url = imgUrl
  }
  
  func setImageWith(image image: UIImage) {
    thumbImageView.image = image
  }
  
  func setBorderWidth(width: CGFloat) {
    leftMarginConstraint.constant = width
    rightMarginConstraint.constant = width
    
  }
  
}

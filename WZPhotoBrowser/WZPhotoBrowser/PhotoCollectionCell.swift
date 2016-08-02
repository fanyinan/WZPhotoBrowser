//
//  PhotoCollectionCell.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 16/6/9.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

class PhotoCollectionCell: UICollectionViewCell {
  
  var zoomImageScrollView: ZoomImageScrollView!
  var padding: CGFloat = 0 {
    didSet{
      zoomImageScrollView.frame = CGRect(x: padding, y: 0, width: frame.width - padding * CGFloat(2), height: frame.height)
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    zoomImageScrollView = ZoomImageScrollView()
    zoomImageScrollView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    contentView.addSubview(zoomImageScrollView)
    
  }
  
  func setImageUrl(imageUrl: String, placeholderImage: UIImage? = nil, loadNow: Bool = true) {
    zoomImageScrollView.setImageUrl(imageUrl, placeholderImage: placeholderImage, loadNow: loadNow)
  }
  
  func setLocalImage(image: UIImage) {
    zoomImageScrollView.setLocalImage(image)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

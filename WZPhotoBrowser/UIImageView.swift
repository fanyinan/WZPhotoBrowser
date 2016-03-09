//
//  UIImageView.swift
//  MuMu
//
//  Created by 范祎楠 on 15/8/18.
//  Copyright © 2015年 juxin. All rights reserved.
//

enum NetImageStyle {
  case Cut
  case OriginScale
}

extension UIImageView {

  var url: String {
    get{
      return self.url
    }
    
    set{
      self.imageWithUrl(newValue)
    }
  }
  
  func imageWithUrl(url: String, size: CGSize, imageStyle: NetImageStyle, plachholderImage: UIImage? = nil, completed: ((UIImage) -> Void)? = nil) {
    
    let newUrl = url.getImageUrlWithSize(size, imageStyle: imageStyle)
//    let newUrl = url
    if let _plachholderImage = plachholderImage {
      
      if let _completed = completed {
        self.sd_setImageWithURL(NSURL(string: newUrl)!, placeholderImage: _plachholderImage, completed: { (image, error, sDImageCacheType, url) -> Void in
          if error == nil {
            _completed(image)
          }
        })
      } else {
        self.sd_setImageWithURL(NSURL(string: newUrl)!, placeholderImage: _plachholderImage)
      }
    } else {
      if let _completed = completed {
        self.sd_setImageWithURL(NSURL(string: newUrl)!, completed: { (image, error, sDImageCacheType, url) -> Void in
          if error == nil {
            _completed(image)
          }
        })
      } else {
        self.sd_setImageWithURL(NSURL(string: newUrl)!)
      }
    }

  }
  
  func imageWithUrl(url: String, plachholderImage: UIImage? = nil, completed: ((UIImage) -> Void)? = nil) {
    imageWithUrl(url, size: self.frame.size, imageStyle: .Cut,plachholderImage: plachholderImage, completed: completed)
  }
  
  func imageWithUrlNoCut(url: String, plachholderImage: UIImage? = nil, completed: ((UIImage) -> Void)? = nil) {
    imageWithUrl(url, size: self.frame.size, imageStyle: .OriginScale, plachholderImage: plachholderImage, completed: completed)
  }
  
}

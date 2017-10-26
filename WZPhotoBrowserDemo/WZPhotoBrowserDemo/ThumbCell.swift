//
//  VisitedMeCollectionViewCell.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/7/17.
//  Copyright © 2015年 fyn. All rights reserved.
//

import UIKit
import SDWebImage

class ThumbCell: UICollectionViewCell {
  
  @IBOutlet weak var avatarImageView: UIImageView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    avatarImageView.contentMode = UIViewContentMode.scaleAspectFill

  }
  
  func setData(_ imgUrl: String){
    avatarImageView.sd_setImage(with: URL(string: imgUrl))
  }
}

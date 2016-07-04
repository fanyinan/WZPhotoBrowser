//
//  WZPhotoCollectionViewFlowLayout.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 16/6/15.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

class WZPhotoCollectionViewFlowLayout: UICollectionViewFlowLayout {

  var indexPathsToAnimation: [NSIndexPath] = []

  override func prepareLayout() {
    super.prepareLayout()
  }
  
  override func prepareForCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
    
    for updateItem in updateItems {
      if updateItem.updateAction == .Delete {
        if let index = updateItem.indexPathBeforeUpdate {
          indexPathsToAnimation += [index]
        }
      }
    }
  }
  
  override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    
    let attr = layoutAttributesForItemAtIndexPath(itemIndexPath)?.copy() as! UICollectionViewLayoutAttributes

    if indexPathsToAnimation.contains(itemIndexPath) {
      
      attr.alpha = 0.0
      attr.transform = CGAffineTransformMakeScale(0.2, 0.2)
      
      indexPathsToAnimation.removeAtIndex(indexPathsToAnimation.indexOf(itemIndexPath)!)
      
    }
    
    return  attr
  }
  
  override func finalizeCollectionViewUpdates() {
    super.finalizeCollectionViewUpdates()
    indexPathsToAnimation.removeAll()
  }
  
}

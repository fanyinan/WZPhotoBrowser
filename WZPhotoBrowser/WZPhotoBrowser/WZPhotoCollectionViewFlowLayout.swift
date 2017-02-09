//
//  WZPhotoCollectionViewFlowLayout.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 16/6/15.
//  Copyright © 2016年 范祎楠. All rights reserved.
//

import UIKit

class WZPhotoCollectionViewFlowLayout: UICollectionViewFlowLayout {

  var indexPathsToAnimation: [IndexPath] = []

  override func prepare() {
    super.prepare()
  }
  
  override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
    
    for updateItem in updateItems {
      if updateItem.updateAction == .delete {
        if let index = updateItem.indexPathBeforeUpdate {
          indexPathsToAnimation += [index]
        }
      }
    }
  }
  
  override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    
    let attr = layoutAttributesForItem(at: itemIndexPath)?.copy() as! UICollectionViewLayoutAttributes

    if indexPathsToAnimation.contains(itemIndexPath) {
      
      attr.alpha = 0.0
      attr.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
      
      indexPathsToAnimation.remove(at: indexPathsToAnimation.index(of: itemIndexPath)!)
      
    }
    
    return  attr
  }
  
  override func finalizeCollectionViewUpdates() {
    super.finalizeCollectionViewUpdates()
    indexPathsToAnimation.removeAll()
  }
  
}

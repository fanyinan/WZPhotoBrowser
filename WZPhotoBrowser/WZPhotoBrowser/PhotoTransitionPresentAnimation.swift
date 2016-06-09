//
//  PhotoTransitionPushAnimation.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/11/22.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class PhotoTransitionPresentAnimation: NSObject, UIViewControllerAnimatedTransitioning {
  
  weak var showVC: WZPhotoBrowserAnimatedTransition?
  
  init(showVC: WZPhotoBrowserAnimatedTransition) {
    self.showVC = showVC
    super.init()
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return 0.3
  }
  
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    
    guard let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? WZPhotoBrowser else { return }
    guard let _showVC = showVC else { return }
    guard let containerView = transitionContext.containerView() else { return }
    
    let toView = toVC.view
    toView.alpha = 0
    containerView.addSubview(toView)
    toVC.setMainTableViewHiddenForAnimation(true)
    
    let imageFrameInScreen = _showVC.getImageViewFrameInScreenWith(nil) ?? CGRectZero
    let imageViewForAnimation = UIImageView(frame: imageFrameInScreen)
    containerView.addSubview(imageViewForAnimation)
    imageViewForAnimation.contentMode = .ScaleAspectFill
    imageViewForAnimation.clipsToBounds = true
    imageViewForAnimation.image = _showVC.getImageForAnimation()
    
    let finalRect = toVC.getCurrentDisplayImageRect()
    
    UIView.animateWithDuration(transitionDuration(transitionContext), animations: { () -> Void in
      
      imageViewForAnimation.frame = finalRect
      imageViewForAnimation.center = toView.center
      toView.alpha = 1
      
      }) { _ in
        
        toVC.setMainTableViewHiddenForAnimation(false)
        imageViewForAnimation.removeFromSuperview()
        transitionContext.completeTransition(true)
        toVC.completePresent()
        
    }
    
  }
}

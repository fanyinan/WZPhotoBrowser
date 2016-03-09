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
        
    let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? WZPhotoBrowser
    
    guard toVC != nil else {
      return
    }
    
    let toView = toVC!.view
    toView.alpha = 0
    transitionContext.containerView()?.addSubview(toView)
    toVC!.setMainTableViewHiddenForAnimation(true)
    
    let imageFrameInFromVC = showVC!.getImageViewFrameInParentViewWith(nil)!
    let imageViewForAnimation = UIImageView(frame: CGRectOffset(imageFrameInFromVC, 0, 64))
    imageViewForAnimation.image = showVC!.getImageForAnimation()
    imageViewForAnimation.contentMode = .ScaleAspectFill
    imageViewForAnimation.clipsToBounds = true
    transitionContext.containerView()?.addSubview(imageViewForAnimation)
    
    let finalSize = toVC!.getCurrentDisplayImageSize()
    
    UIView.animateWithDuration(transitionDuration(transitionContext), animations: { () -> Void in
      
      imageViewForAnimation.frame = CGRect(origin: imageViewForAnimation.frame.origin, size: finalSize)
      imageViewForAnimation.center = toView.center
      toView.alpha = 1
      
      }) { _ in
        
        toVC!.setMainTableViewHiddenForAnimation(false)
        imageViewForAnimation.removeFromSuperview()
        transitionContext.completeTransition(true)
        toVC!.completePresent()
        
    }
    
  }
}

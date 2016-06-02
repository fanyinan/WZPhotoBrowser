//
//  PhotoTransitionPopAnimation.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/11/22.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class PhotoTransitionDismissAnimation: NSObject, UIViewControllerAnimatedTransitioning {
  
  weak var showVC: WZPhotoBrowserAnimatedTransition?
  
  init(showVC: WZPhotoBrowserAnimatedTransition) {
    self.showVC = showVC
    super.init()
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
    return 0.3
  }
  
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    
    guard let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? WZPhotoBrowser else {
      return }
    guard let  toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else { return }
    guard let containerView = transitionContext.containerView() else { return }
    guard let _showVC = showVC else { return }

    containerView.addSubview(toVC.view)
    containerView.sendSubviewToBack(toVC.view)
    
    let fromView = fromVC.view
    fromView.alpha = 1
    fromVC.setMainTableViewHiddenForAnimation(true)
    
    //初始化负责动画的ImageView
    let imageSizeInFromVC = fromVC.getCurrentDisplayImageSize()
    let imageViewForAnimation = UIImageView(frame: CGRect(origin: CGPointZero, size: imageSizeInFromVC))
    containerView.addSubview(imageViewForAnimation)
    imageViewForAnimation.center = fromView.center
    imageViewForAnimation.contentMode = .ScaleAspectFill
    imageViewForAnimation.clipsToBounds = true
    imageViewForAnimation.image = fromVC.getCurrentDisplayImage()
    
    
    var finalFrame = CGRectZero
    var isHaveTargetFrame: Bool!
    
    //如果没有获得最终的位置，则已fade的形式消失
    if let imageFrameInScreen = _showVC.getImageViewFrameInScreenWith(fromVC.currentIndex) {
      
      finalFrame = imageFrameInScreen
      isHaveTargetFrame = true
      
    } else {
      
      //动画结束时图片的放大比例
      let fadeFinalScale: CGFloat = 1.5
      
      var tmpFrame = imageViewForAnimation.frame
      tmpFrame.size = CGSize(width: imageViewForAnimation.frame.size.width * fadeFinalScale, height: imageViewForAnimation.frame.size.height * fadeFinalScale)
      tmpFrame.origin = CGPoint(x:  (containerView.frame.width - tmpFrame.size.width) / 2, y: (containerView.frame.height - tmpFrame.size.height) / 2)
      finalFrame = tmpFrame
      isHaveTargetFrame = false
    }
    
    UIView.animateWithDuration(transitionDuration(transitionContext), animations: { () -> Void in
      
      fromView.alpha = 0
      imageViewForAnimation.frame = finalFrame
      
      if !isHaveTargetFrame {
        imageViewForAnimation.alpha = 0
      }
      
      }) { _ in
        
        imageViewForAnimation.removeFromSuperview()
        transitionContext.completeTransition(true)
        
    }
    
  }
  
}

//
//  PhotoTransitionPopAnimation.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/11/22.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

public class PhotoTransitionDismissAnimation: NSObject, UIViewControllerAnimatedTransitioning {
  
  weak var showVC: WZPhotoBrowserAnimatedTransitionDataSource?
  
  public init(showVC: WZPhotoBrowserAnimatedTransitionDataSource) {
    self.showVC = showVC
    super.init()
  }
  
  public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.3
  }
  
  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
    guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? WZPhotoBrowser else {
      return }
    guard let  toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
    let containerView = transitionContext.containerView
    guard let _showVC = showVC else { return }
    
    containerView.addSubview(toVC.view)
    containerView.sendSubview(toBack: toVC.view)
    containerView.backgroundColor = UIColor.clear
    
    let fromView = fromVC.view
    fromView?.alpha = 1
    fromVC.setMainTableViewHiddenForAnimation(true)
    
    //初始化负责动画的ImageView
    let imageSizeInFromVC = fromVC.getCurrentDisplayImageRect()
    let imageViewForAnimation = UIImageView(frame: imageSizeInFromVC)
    containerView.addSubview(imageViewForAnimation)
    imageViewForAnimation.contentMode = .scaleAspectFill
    imageViewForAnimation.clipsToBounds = true
    imageViewForAnimation.image = fromVC.getCurrentDisplayImage()
    
    
    var finalFrame = CGRect.zero
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
    
    (self.showVC as? WZPhotoBrowserAnimatedTransitionDelegate)?.animatedTransitionBeginDismissViewController?(imageViewForAnimation)
    
    UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { () -> Void in
      
      fromView?.alpha = 0
      imageViewForAnimation.frame = finalFrame
      
      if !isHaveTargetFrame {
        imageViewForAnimation.alpha = 0
      }
      
      //I know it is like a shit, but it's cool
      ((self.showVC as? WZPhotoBrowserAnimatedTransitionDelegate)?.animateBlockWhenDismissingViewController?(imageViewForAnimation))?()
      
      }, completion: { _ in
        
        imageViewForAnimation.removeFromSuperview()
        transitionContext.completeTransition(true)
        
        (self.showVC as? WZPhotoBrowserAnimatedTransitionDelegate)?.animatedTransitionEndDismissViewController?(imageViewForAnimation)
        
    }) 
    
  }
  
}

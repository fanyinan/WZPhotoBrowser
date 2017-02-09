//
//  PhotoTransitionPushAnimation.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/11/22.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

public class PhotoTransitionPresentAnimation: NSObject, UIViewControllerAnimatedTransitioning {
  
  weak var showVC: WZPhotoBrowserAnimatedTransitionDataSource?
  
  public init(showVC: WZPhotoBrowserAnimatedTransitionDataSource) {
    self.showVC = showVC
    super.init()
  }
  
  public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.3
  }
  
  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
    guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? WZPhotoBrowser else { return }
    guard let _showVC = showVC else { return }
    let containerView = transitionContext.containerView
    
    guard let toView = toVC.view else { return }
    toView.alpha = 0
    toVC.setMainTableViewHiddenForAnimation(true)
    
    containerView.addSubview(toView)
    containerView.backgroundColor = UIColor.clear
    
    let imageFrameInScreen = _showVC.getImageViewFrameInScreenWith(nil) ?? CGRect.zero
    let imageViewForAnimation = UIImageView(frame: imageFrameInScreen)
    containerView.addSubview(imageViewForAnimation)
    imageViewForAnimation.contentMode = .scaleAspectFill
    imageViewForAnimation.clipsToBounds = true
    imageViewForAnimation.image = _showVC.getImageForAnimation()
    
    let finalRect = toVC.getCurrentDisplayImageRect()
    
    (self.showVC as? WZPhotoBrowserAnimatedTransitionDelegate)?.animatedTransitionBeginPresentViewController?(imageViewForAnimation)
    
    UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { () -> Void in
      
      imageViewForAnimation.frame = finalRect
      imageViewForAnimation.center = toView.center
      toView.alpha = 1
      
      //I know it is like a shit, but it's cool
      ((self.showVC as? WZPhotoBrowserAnimatedTransitionDelegate)?.animateInBlockWhenPresentingViewController?(imageViewForAnimation))?()
      
      }, completion: { _ in
        
        toVC.setMainTableViewHiddenForAnimation(false)
        imageViewForAnimation.removeFromSuperview()
        transitionContext.completeTransition(true)
        toVC.completePresent()
        
        (self.showVC as? WZPhotoBrowserAnimatedTransitionDelegate)?.animatedTransitionEndPresentViewController?(imageViewForAnimation)
        
    }) 
    
  }
}

//
//  ZoomImageScrollView.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/1.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

class ZoomImageScrollView: UIScrollView {
  
  private var imageView: UIImageView!
  private var singleTap: UITapGestureRecognizer!
  private var doubleTap: UITapGestureRecognizer!
  private var placeHolderImageSize: CGSize?
  private var netImageSize: CGSize!
  private var isLoaded = false // 是否加载完大图
  private var isAnimation = false //标识此刻是否为放大动画，如果是则手动调整大小执行moveFrameToCenter，不执行layoutsubviews的moveFrameToCenter
  private var progressView: LoadImageProgressView!
  private var initialZoomScale: CGFloat! //保存初始比例，供双击放大后还原使用
  
  let maxScale: CGFloat = 3
  
  init(){
    super.init(frame: CGRectZero)
    configUI()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    if !isAnimation {
      moveFrameToCenter()
    }
    
  }
  
  /**
   设置图片
   
   - parameter imageUrl:         图片url
   - parameter placeholderImage: 占位图
   - parameter loadNow:          是否立即加载，用户动画push时在完全显示出来后再去加载图片
   */
  func setImageUrl(imageUrl: String, placeholderImage: UIImage? = nil, loadNow: Bool = true) {
    
    minimumZoomScale = 1
    maximumZoomScale = 1
    zoomScale = 1
    imageView.frame = bounds
    contentOffset = CGPoint.zero
    
    isLoaded = false
    placeHolderImageSize = nil
    
    let currentTag = (tag + 1) % 100
    tag = currentTag
    
    //如果图片没有被缓存过则显示默认图片站位
    if !SDImageCache.sharedImageCache().diskImageExistsWithKey(imageUrl) {
      placeHolderImageSize = placeholderImage?.size
      
      self.setImage(placeholderImage)
      progressView.hidden = false
      
      guard loadNow else {
        return
      }
      
      imageView.sd_setImageWithURL(NSURL(string: imageUrl), placeholderImage: placeholderImage, options: .AvoidAutoSetImage, progress: { (current, total) -> Void in
        
        guard currentTag == self.tag else { return }
        
        self.progressView.progress = CGFloat(current) / CGFloat(total)
        
      }) { (image, error, SDImageCacheType, url) -> Void in
        if error == nil{
          
          guard currentTag == self.tag else { return }
          
          self.progressView.dismiss()
          self.didFetchImageWith(image)
          
        }
      }
      
    } else {
      
      progressView.hidden = true
      let image = SDImageCache.sharedImageCache().imageFromDiskCacheForKey(imageUrl)
      didFetchImageWith(image)
      
    }
    
  }
  
  /**
   用本地图片设置
   
   - parameter image: image
   */
  func setLocalImage(image: UIImage) {
    
    netImageSize = image.size
    isLoaded = true
    setImage(image)
  }
  
  /**
   图片点击事件
   
   :param: target target
   :param: action action
   */
  func addImageTarget(target: AnyObject, action: Selector) {
    singleTap.addTarget(target, action: action)
  }
  
  func imageViewDoubleTap(tap: UITapGestureRecognizer) {
    
    guard isLoaded else { return }
    
    guard zoomScale == initialZoomScale else {
      
      setZoomScale(initialZoomScale, animated: true)
      return
    }
    
    let position = tap.locationInView(imageView)
    
    let zoomRectScale: CGFloat = 2
    
    // "/ zoomScale"将尺寸还原为zoomscale为1时的尺寸
    let zoomWidth = frame.width / zoomScale / zoomRectScale
    let zoomHeight = frame.height / zoomScale / zoomRectScale
    //position为zoomscale为1时的位置; "* zoomScale":转为当前zoomscale下的position
    //"/ imageView.frame.width * frame.width" 将点击的位置按比例转为scrollview上的位置
    //"/ zoomScale":再将位置还原为zoomscale为1时的位置
    //当zoomScale为1时还是有瑕疵，待改进
    let zoomX = position.x * zoomScale / imageView.frame.width * frame.width / zoomScale - zoomWidth / 2
    let zoomY = position.y * zoomScale / imageView.frame.height * frame.height / zoomScale - zoomHeight / 2
    
    //此值为在zoomscale为1时图片上的尺寸
    //用于表示要把这个以点击位置为center的rect区域缩放zoomRectScale倍
    //此处需要解决：当以zoomRectScale放大后，图片的高超过屏幕的高度，此时不应该再动画的时候执行moveFrameToCenter，而应根据点击位置调整
    let zoomRect = CGRect(x: zoomX, y: zoomY, width: zoomWidth, height: zoomHeight)
    zoomToRect(zoomRect, animated: true)
    
  }
  
  private func configUI() {
    backgroundColor = UIColor.blackColor()
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollViewDecelerationRateFast
    //    autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    alwaysBounceHorizontal = false
    delegate = self
    scrollEnabled = false //使图片开始是不能滑动的，因为当图片宽为600左右，scale为0.533左右时，htable无法滑动，具体原因不明
    
    //imageview
    imageView = UIImageView(frame: CGRectZero)
    imageView.backgroundColor = UIColor.blackColor()
    imageView.contentMode = .ScaleAspectFill
    imageView.userInteractionEnabled = true
    
    singleTap = UITapGestureRecognizer()
    addGestureRecognizer(singleTap)
    
    doubleTap = UITapGestureRecognizer(target: self, action: #selector(ZoomImageScrollView.imageViewDoubleTap(_:)))
    doubleTap.numberOfTapsRequired = 2
    imageView.addGestureRecognizer(doubleTap)
    singleTap.requireGestureRecognizerToFail(doubleTap)
    
    addSubview(imageView)
    
    initProgressView()
  }
  
  private func initProgressView() {
    
    let progressWidth: CGFloat = 100
    let progressheight: CGFloat = 100
    let x: CGFloat = (CGRectGetWidth(frame) - progressWidth) / 2
    let y: CGFloat = (CGRectGetHeight(frame) - progressheight) / 2
    progressView = LoadImageProgressView(frame: CGRect(x: x, y: y, width: progressWidth, height: progressWidth))
    progressView.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
    addSubview(progressView)
    
  }
  
  private func setImage(image: UIImage?) {
    
    if image == nil {
      progressView.setWhiteStyle()
      return
    }
    
    progressView.setBlackStyle()
    imageView.image = image
    //这里设置imageview的size为imagesize在当前缩放比例下的size
    imageView.frame = CGRect(x: 0, y: 0, width: image!.size.width * zoomScale, height: image!.size.height * zoomScale)
    //    contentSize = imageView.frame.size //不用手动设置
    
    calculateZoomScale()
  }
  
  private func didFetchImageWith(image: UIImage) {
    
    self.netImageSize = image.size
    self.isLoaded = true
    self.setImage(image)
    self.isAnimation = false
  }
  
  private func calculateZoomScale() {
    
    let boundsSize = bounds.size
    let imageSize = isLoaded == true ? netImageSize : placeHolderImageSize!
    
    let scaleX = boundsSize.width / imageSize.width
    let scaleY = boundsSize.height / imageSize.height
    
    var minScale = min(scaleX, scaleY)
    
    //如果图片长宽都小于屏幕则不缩放
    if scaleX > 1.0 && scaleY > 1.0 {
      minScale = 1.0
      
    }
    
    if !isLoaded {
      
      minScale = reducePlaceHolderIfNeed(minScale)
      
    }
    
    maximumZoomScale = maxScale
    
    if placeHolderImageSize != nil && self.isLoaded == true {
      
      //此时已经换了一张大图，但是需要先缩小到之前的比例，以便进行动画
      //这里使用的占位图片的尺寸应为实际显示出来的尺寸，因为占位图的缩放比例用reducePlaceHolderIfNeed处理过
      let scaleForPlaceHolder = self.placeHolderImageSize!.width * zoomScale / imageSize.width
      
      minimumZoomScale = scaleForPlaceHolder
      zoomScale = scaleForPlaceHolder
      
      setNeedsLayout()
      layoutIfNeeded()
      
      isAnimation = true
      UIView.animateWithDuration(0.2, animations: { () -> Void in
        
        self.minimumZoomScale = minScale
        self.zoomScale = self.minimumZoomScale
        self.initialZoomScale = self.zoomScale
        self.moveFrameToCenter()
      })
      
    } else {
      
      isAnimation = false
      minimumZoomScale = minScale
      zoomScale = minimumZoomScale
      initialZoomScale = zoomScale
      
    }
    
    setNeedsLayout()
  }
  
  private func moveFrameToCenter() {
    
    let boundsSize = bounds.size
    var frameToCenter = imageView.frame
    
    if boundsSize.width > frameToCenter.size.width {
      frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / CGFloat(2)
    } else {
      frameToCenter.origin.x = 0
    }
    
    if boundsSize.height > frameToCenter.size.height {
      frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / CGFloat(2)
    } else {
      frameToCenter.origin.y = 0
    }
    
    if !CGRectEqualToRect(imageView.frame, frameToCenter) {
      imageView.frame = frameToCenter
    }
    
  }
  
  //当占位图比较大时看着不爽
  private func reducePlaceHolderIfNeed(scale: CGFloat) -> CGFloat {
    
    //    return scale
    
    guard placeHolderImageSize != nil else {
      return scale
    }
    
    let limite: CGFloat = 2 / 3
    let reduceLimite: CGFloat = 1 / 2
    
    if placeHolderImageSize!.width > bounds.width * limite || placeHolderImageSize!.height > bounds.height * limite {
      
      return scale * reduceLimite
    }
    
    return scale
  }
  
  //for transitionAnimation push
  func getImageRectForAnimation() -> CGRect {
    
    return convertRect(imageView.frame, toView: nil)
  }
  
  //for transitionAnimation pop
  func getImageForAnimation() -> UIImage? {
    return imageView.image
  }
}

extension ZoomImageScrollView: UIScrollViewDelegate {
  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
    scrollEnabled = true
  }
  
  //主要是解决先缩小后再松手弹回来时不会执行moveFrameToCenter()的问题
  func scrollViewDidZoom(scrollView: UIScrollView) {
    setNeedsLayout()
    layoutIfNeeded()
  }
}
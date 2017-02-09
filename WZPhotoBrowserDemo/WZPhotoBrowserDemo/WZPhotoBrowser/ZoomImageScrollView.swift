//
//  ZoomImageScrollView.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/1.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import SDWebImage

class ZoomImageScrollView: UIScrollView {
  
  fileprivate var imageView: UIImageView!
  fileprivate var singleTap: UITapGestureRecognizer!
  fileprivate var doubleTap: UITapGestureRecognizer!
  fileprivate var placeHolderImageSize: CGSize?
  fileprivate var netImageSize: CGSize!
  fileprivate var isLoaded = false // 是否加载完大图
  fileprivate var isAnimation = false //标识此刻是否为放大动画，如果是则手动调整大小执行moveFrameToCenter，不执行layoutsubviews的moveFrameToCenter
  fileprivate var progressView: LoadImageProgressView!
  fileprivate var initialZoomScale: CGFloat! //保存初始比例，供双击放大后还原使用
  
  var doubleTapMagnify = false {
    didSet{
      
      guard doubleTapMagnify else { return }
        
      doubleTap = UITapGestureRecognizer(target: self, action: #selector(ZoomImageScrollView.imageViewDoubleTap(_:)))
      doubleTap.numberOfTapsRequired = 2
      imageView.addGestureRecognizer(doubleTap)
      singleTap.require(toFail: doubleTap)
    }
  }
  
  let maxScale: CGFloat = 3
  
  init(){
    super.init(frame: CGRect.zero)
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
  func setImageUrl(_ imageUrl: String, placeholderImage: UIImage? = nil, loadNow: Bool = true) {
    
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
    if let image = SDImageCache.shared().imageFromCache(forKey: imageUrl) {
      
      progressView.isHidden = true
      didFetchImageWith(image)
      return
    }
    
    placeHolderImageSize = placeholderImage?.size
    
    self.setImage(placeholderImage)
    progressView.isHidden = false
    
    guard loadNow else {
      return
    }
    
    self.imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: placeholderImage, options: .avoidAutoSetImage, progress: { (current, total, URL) -> Void in
      
      DispatchQueue.main.async {
        
        guard currentTag == self.tag else { return }
        
        self.progressView.progress = CGFloat(current) / CGFloat(total)
      }
      
    }) { (image, error, SDImageCacheType, url) -> Void in
      
      guard let image = image, error == nil else { return }
      
      guard currentTag == self.tag else { return }
      
      self.progressView.dismiss()
      self.didFetchImageWith(image)
      
    }
  }
  
  /**
   用本地图片设置
   
   - parameter image: image
   */
  func setLocalImage(_ image: UIImage) {
    
    //TODO 懒加载
    progressView.isHidden = true
    netImageSize = image.size
    isLoaded = true
    setImage(image)
  }
  
  /**
   图片点击事件
   
   :param: target target
   :param: action action
   */
  func addImageTarget(_ target: AnyObject, action: Selector) {
    singleTap.addTarget(target, action: action)
  }
  
  func imageViewDoubleTap(_ tap: UITapGestureRecognizer) {
    
    guard isLoaded else { return }
    
    guard zoomScale == initialZoomScale else {
      
      setZoomScale(initialZoomScale, animated: true)
      return
    }
    
    let position = tap.location(in: imageView)
    
    let zoomRectScale: CGFloat = 2
    
    let zoomWidth = (netImageSize.width + imageView.frame.minX * 2) / zoomRectScale
    let zoomHeight = (netImageSize.height + imageView.frame.minY * 2) / zoomRectScale
    
    let zoomX = position.x - zoomWidth / 2 - imageView.frame.minX / zoomRectScale
    let zoomY = position.y - zoomHeight / 2 - imageView.frame.minY / zoomRectScale
    
    let zoomRect = CGRect(x: zoomX, y: zoomY, width: zoomWidth, height: zoomHeight)
    zoom(to: zoomRect, animated: true)
    
  }
  
  fileprivate func configUI() {
    backgroundColor = UIColor.black
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollViewDecelerationRateFast
    alwaysBounceHorizontal = false
    delegate = self
    isScrollEnabled = false //使图片开始是不能滑动的，因为当图片宽为600左右，scale为0.533左右时，htable无法滑动，具体原因不明
    
    //imageview
    imageView = UIImageView(frame: CGRect.zero)
    imageView.backgroundColor = UIColor.black
    imageView.contentMode = .scaleAspectFill
    imageView.isUserInteractionEnabled = true
    
    singleTap = UITapGestureRecognizer()
    addGestureRecognizer(singleTap)
    
    addSubview(imageView)
    
    initProgressView()
  }
  
  fileprivate func initProgressView() {
    
    let progressWidth: CGFloat = 100
    let progressheight: CGFloat = 100
    let x: CGFloat = (frame.width - progressWidth) / 2
    let y: CGFloat = (frame.height - progressheight) / 2
    progressView = LoadImageProgressView(frame: CGRect(x: x, y: y, width: progressWidth, height: progressWidth))
    progressView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
    addSubview(progressView)
    
  }
  
  fileprivate func setImage(_ image: UIImage?) {
    
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
  
  fileprivate func didFetchImageWith(_ image: UIImage) {
    
    self.netImageSize = image.size
    self.isLoaded = true
    self.setImage(image)
    self.isAnimation = false
  }
  
  fileprivate func calculateZoomScale() {
    
    let boundsSize = bounds.size
    let imageSize = isLoaded == true ? netImageSize : placeHolderImageSize!
    
    let scaleX = boundsSize.width / (imageSize?.width)!
    let scaleY = boundsSize.height / (imageSize?.height)!
    
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
      let scaleForPlaceHolder = self.placeHolderImageSize!.width * zoomScale / (imageSize?.width)!
      
      minimumZoomScale = scaleForPlaceHolder
      zoomScale = scaleForPlaceHolder
      
      setNeedsLayout()
      layoutIfNeeded()
      
      isAnimation = true
      UIView.animate(withDuration: 0.2, animations: { () -> Void in
        
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
  
  fileprivate func moveFrameToCenter() {
    
    let boundsSize = bounds.size
    let imageViewSize = imageView.frame.size
    
    var adjustX: CGFloat = 0
    var adjustY: CGFloat = 0
    
    if boundsSize.width > imageViewSize.width {
      adjustX = (boundsSize.width - imageViewSize.width) / 2
    }
    
    if boundsSize.height > imageViewSize.height {
      adjustY = (boundsSize.height - imageViewSize.height) / 2
    }
    
    if imageView.frame.minX != adjustX {
      imageView.frame.origin.x = adjustX
    }
    
    if imageView.frame.minY != adjustY {
      imageView.frame.origin.y = adjustY
    }
  }
  
  //当占位图比较大时看着不爽
  fileprivate func reducePlaceHolderIfNeed(_ scale: CGFloat) -> CGFloat {
    
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
    
    return convert(imageView.frame, to: nil)
  }
  
  //for transitionAnimation pop
  func getImageForAnimation() -> UIImage? {
    return imageView.image
  }
}

extension ZoomImageScrollView: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    isScrollEnabled = true
  }
  
  //主要是解决先缩小后再松手弹回来时不会执行moveFrameToCenter()的问题
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    setNeedsLayout()
    layoutIfNeeded()
    
  }
  
}

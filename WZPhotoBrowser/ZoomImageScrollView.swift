//
//  ZoomImageScrollView.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/1.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import SDWebImage
import FLAnimatedImage

class ZoomImageScrollView: UIScrollView {
  
  fileprivate var imageView: FLAnimatedImageView!
  private var singleTap: UITapGestureRecognizer!
  private var doubleTap: UITapGestureRecognizer!
  private var placeHolderImageSize: CGSize?
  private var netImageSize: CGSize = CGSize.zero
  private var isLoaded = false // 是否加载完大图
  private var isAnimation = false //标识此刻是否为放大动画，如果是则手动调整大小执行moveFrameToCenter，不执行layoutsubviews的moveFrameToCenter
  private var progressView: LoadImageProgressView!
  private var initialZoomScale: CGFloat! //保存初始比例，供双击放大后还原使用
  
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
    setupUI()
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
  
  func setImage(with imageURL: String, placeholderImage: UIImage? = nil, loadNow: Bool = true) {
    
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
    if let image = SDImageCache.shared().imageFromCache(forKey: imageURL) {
      
      progressView.isHidden = true
      didFetchImage(imageSize: image.size)
      
      DispatchQueue.global().async {
        
        guard let path = SDImageCache.shared().defaultCachePath(forKey: imageURL) else { return }
        guard let data = FileManager.default.contents(atPath: path) else { return }
        
        self.setGIFImage(with: data, tag: currentTag)

      }
      
      return
    }
    
    placeHolderImageSize = placeholderImage?.size
    
    imageView.image = placeholderImage
    setImageViewSize(with: placeHolderImageSize)
    progressView.isHidden = false
    
    guard loadNow else {
      return
    }
    
    SDWebImageDownloader.shared().downloadImage(with: URL(string: imageURL), options: [], progress: { (current, total, URL) -> Void in
      
      DispatchQueue.main.async {
        
        guard currentTag == self.tag else { return }
        
        self.progressView.progress = CGFloat(current) / CGFloat(total)
      }
      
    }) { (_, data, error, _) in
      
      guard let data = data else { return }
      
      DispatchQueue.global().async {
        
        SDImageCache.shared().storeImageData(toDisk: data, forKey: imageURL)

        self.setGIFImage(with: data, tag: currentTag) { imageSize in
        
          guard let imageSize = imageSize else { return }
          
          self.progressView.dismiss()
          self.didFetchImage(imageSize: imageSize)
          
        }
      }
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
    imageView.image = image
    setImageViewSize(with: image.size)
  }
  
  /**
   图片点击事件
   
   :param: target target
   :param: action action
   */
  func addImageTarget(_ target: AnyObject, action: Selector) {
    singleTap.addTarget(target, action: action)
  }
  
  @objc func imageViewDoubleTap(_ tap: UITapGestureRecognizer) {
    
    guard isLoaded else { return }
    
    guard zoomScale == initialZoomScale else {
      
      setZoomScale(initialZoomScale, animated: true)
      return
    }
    
    let position = tap.location(in: imageView)
    
    let zoomRectScale: CGFloat = 2
    
    let zoomWidth = frame.width / zoomScale / zoomRectScale
    let zoomHeight = frame.height / zoomScale / zoomRectScale
    
    let zoomX = position.x - zoomWidth / 2 - imageView.frame.minX / zoomScale / zoomRectScale
    let zoomY = position.y - zoomHeight / 2 - imageView.frame.minY / zoomScale / zoomRectScale
    
    let zoomRect = CGRect(x: zoomX, y: zoomY, width: zoomWidth, height: zoomHeight)
    zoom(to: zoomRect, animated: true)
    
  }
  
  private func setGIFImage(with data: Data, tag: Int, completion: ((CGSize?) -> Void)? = nil) {
    
    let flAnimatedImage = FLAnimatedImage(animatedGIFData: data)
    let image = UIImage(data: data)
    
    DispatchQueue.main.async {
      
      guard tag == self.tag else { return }
      
      var imageSize: CGSize!
      
      if flAnimatedImage != nil {
        imageSize = flAnimatedImage!.size
        self.imageView.animatedImage = flAnimatedImage
      } else {
        imageSize = image?.size
        self.imageView.image = image
      }
      
      completion?(imageSize)
    }
  }
  
  private func setupUI() {
    backgroundColor = UIColor.black
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = UIScrollViewDecelerationRateFast
    alwaysBounceHorizontal = false
    delegate = self
    isScrollEnabled = false //使图片开始是不能滑动的，因为当图片宽为600左右，scale为0.533左右时，htable无法滑动，具体原因不明
    
    //imageview
    imageView = FLAnimatedImageView(frame: CGRect.zero)
    imageView.backgroundColor = UIColor.black
    imageView.contentMode = .scaleAspectFill
    imageView.isUserInteractionEnabled = true
    
    singleTap = UITapGestureRecognizer()
    addGestureRecognizer(singleTap)
    
    addSubview(imageView)
    
    initProgressView()
  }
  
  private func initProgressView() {
    
    let progressWidth: CGFloat = 100
    let progressheight: CGFloat = 100
    let x: CGFloat = (frame.width - progressWidth) / 2
    let y: CGFloat = (frame.height - progressheight) / 2
    progressView = LoadImageProgressView(frame: CGRect(x: x, y: y, width: progressWidth, height: progressWidth))
    progressView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
    addSubview(progressView)
    
  }
  
  private func setImageViewSize(with imageSize: CGSize?) {
    
    guard let imageSize = imageSize else {
      progressView.setWhiteStyle()
      return
    }
    
    progressView.setBlackStyle()
    //这里设置imageview的size为imagesize在当前缩放比例下的size
    imageView.frame = CGRect(x: 0, y: 0, width: imageSize.width * zoomScale, height: imageSize.height * zoomScale)
    //    contentSize = imageView.frame.size //不用手动设置
    
    calculateZoomScale()
  }
  
  private func didFetchImage(imageSize: CGSize) {
    
    netImageSize = imageSize
    isLoaded = true
    setImageViewSize(with: imageSize)
    isAnimation = false
  }
  
  private func calculateZoomScale() {
    
    let boundsSize = bounds.size
    let imageSize = isLoaded ? netImageSize : placeHolderImageSize!
    
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
    
    if placeHolderImageSize != nil && self.isLoaded {
      
      //此时已经换了一张大图，但是需要先缩小到之前的比例，以便进行动画
      //这里使用的占位图片的尺寸应为实际显示出来的尺寸，因为占位图的缩放比例用reducePlaceHolderIfNeed处理过
      let scaleForPlaceHolder = self.placeHolderImageSize!.width * zoomScale / imageSize.width
      
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
  
  private func moveFrameToCenter() {
    
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
  private func reducePlaceHolderIfNeed(_ scale: CGFloat) -> CGFloat {
    
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

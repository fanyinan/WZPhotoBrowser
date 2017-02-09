//
//  WZPhotoBrowser.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/2.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import SDWebImage

protocol WZPhotoBrowserAnimatedTransitionDataSource: NSObjectProtocol {
  
  //如果index为nil则返回当前点击的即将跳转图片浏器的图片的frame
  func getImageViewFrameInScreenWith(_ index: Int?) -> CGRect?
  
  func getImageForAnimation() -> UIImage?
  
}

@objc protocol WZPhotoBrowserAnimatedTransitionDelegate: NSObjectProtocol {
  
  @objc optional func animatedTransitionBeginPresentViewController(_ animatedImageView: UIImageView)
  
  @objc optional func animateInBlockWhenPresentingViewController(_ animatedImageView: UIImageView) -> ()->Void
  
  @objc optional func animatedTransitionEndPresentViewController(_ animatedImageView: UIImageView)
  
  @objc optional func animatedTransitionBeginDismissViewController(_ animatedImageView: UIImageView)
  
  @objc optional func animateBlockWhenDismissingViewController(_ animatedImageView: UIImageView) -> ()->Void
  
  @objc optional func animatedTransitionEndDismissViewController(_ animatedImageView: UIImageView)
  
}

@objc protocol WZPhotoBrowserDelegate: NSObjectProtocol {
  
  //图片总数
  func numberOfImage(_ photoBrowser: WZPhotoBrowser) -> Int
  //加载网络图片
  @objc optional func displayWebImageWithIndex(_ photoBrowser: WZPhotoBrowser, index: Int) -> String
  //加载本地图片，较网络图片优先判断
  @objc optional func displayLocalImageWithIndex(_ photoBrowser: WZPhotoBrowser, index: Int) -> UIImage?
  //加载网络图片时的占位图片
  @objc optional func placeHolderImageWithIndex(_ photoBrowser: WZPhotoBrowser, index: Int) -> UIImage?
  //第一次进入时显示的图片index，默认为0
  @objc optional func firstDisplayIndex(_ photoBrowser: WZPhotoBrowser) -> Int
  
}

class WZPhotoBrowser: UIViewController {
  
  fileprivate var mainCollectionView: UICollectionView!
  fileprivate var prepareShowCell: PhotoCollectionCell!
  
  weak var delegate: WZPhotoBrowserDelegate?
  var quitBlock: (() -> Void)?
  fileprivate(set) var currentIndex: Int = 0 {
    didSet{
      photoDidChange()
    }
  }
  var isAnimate = false //用于设置是否经过动画跳转来 ，由PhotoTransitionPushAnimation设置
  var isDidShow = false //用于标记次VC是否已经呈现
  var isHideStatusBar = false
  var doubleTapMagnify = false
  
  let IDENTIFIER_IMAGE_CELL = "ZoomImageCell"
  let padding: CGFloat = 6
  
  init(delegate: WZPhotoBrowserDelegate, quitBlock: (() -> Void)? = nil) {
    
    self.delegate = delegate
    self.quitBlock = quitBlock
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    moveToPhoto(with: delegate?.firstDisplayIndex?(self) ?? 0)
    
    //当默认显示第0张时，currentIndex不会被赋值，需要手动赋值，以便调用photoDidChange
    if delegate?.firstDisplayIndex?(self) != nil && (delegate?.firstDisplayIndex?(self))! == 0 {
      currentIndex = 0
    }
    
    hideNavigationBar()
    
    if isAnimate {
      
      //如果需要进行动画，需要提前使布局，通过prepareShowCell获得图片的frame
      view.setNeedsLayout()
      view.layoutIfNeeded()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    isHideStatusBar = true
    setNeedsStatusBarAppearanceUpdate()
  }
  
  override func viewWillLayoutSubviews() {
    prepareShowCell = mainCollectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? PhotoCollectionCell
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    hideNavigationBar()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override var prefersStatusBarHidden : Bool {
    return isHideStatusBar
  }
  
  fileprivate func setupUI() {
    
    automaticallyAdjustsScrollViewInsets = false
    view.backgroundColor = UIColor.black
    view.clipsToBounds = true
    
    initMainTableView()
    
  }
  
  fileprivate func initMainTableView() {
    
    let mainCollectionViewFrame = CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height)
    
    let mainCollectionViewLayout = UICollectionViewFlowLayout()
    mainCollectionViewLayout.itemSize = mainCollectionViewFrame.size
    mainCollectionViewLayout.minimumInteritemSpacing = 0
    mainCollectionViewLayout.minimumLineSpacing = 0
    mainCollectionViewLayout.scrollDirection = .horizontal
    
    mainCollectionView = UICollectionView(frame: mainCollectionViewFrame, collectionViewLayout: mainCollectionViewLayout)
    mainCollectionView.delegate = self
    mainCollectionView.dataSource = self
    mainCollectionView.isPagingEnabled = true
    mainCollectionView.backgroundColor = UIColor.black
    mainCollectionView.register(PhotoCollectionCell.self, forCellWithReuseIdentifier: "PhotoCollectionCell")
    mainCollectionView.showsHorizontalScrollIndicator = false
    
    view.addSubview(mainCollectionView)
    
  }
  
  /**
   收起navigationbar 暂不用
   */
  fileprivate func hideNavigationBar() {
    
    if navigationController == nil {
      return
    }
    
    let isHidden = navigationController!.isNavigationBarHidden
    navigationController!.setNavigationBarHidden(!isHidden, animated: true)
    //    UIApplication.sharedApplication().setStatusBarStyle(isHidden ? .Default : .LightContent, animated: false)
    
    
  }
  
  func moveToPhoto(with index: Int) {
    
    mainCollectionView.setContentOffset(CGPoint(x: CGFloat(index) * mainCollectionView.frame.width, y: 0), animated: false)
    
  }
  
  func onClickPhoto() {
    
    quitBlock?()
    quitBlock = nil
  }
  
  func photoDidChange() {
    
  }
  
  func reload() {
    
    mainCollectionView.reloadData()
    moveToPhoto(with: delegate?.firstDisplayIndex?(self) ?? 0)
  }
  
  //for transitionAnimation
  func getCurrentDisplayImageRect() -> CGRect {
    
    let cell = (mainCollectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? PhotoCollectionCell) ?? prepareShowCell
    return cell?.zoomImageScrollView.getImageRectForAnimation() ?? CGRect.zero
  }
  
  //for transitionAnimation
  func setMainTableViewHiddenForAnimation(_ isHidden: Bool) {
    mainCollectionView.isHidden = isHidden
  }
  
  //for transitionAnimation dismiss
  func getCurrentDisplayImage() -> UIImage? {
    
    let cell = mainCollectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? PhotoCollectionCell
    return cell?.zoomImageScrollView.getImageForAnimation()
  }
  
  //for transitionAnimation presnet
  func completePresent() {
    
    if isAnimate {
      
      isDidShow = true
      let cell = mainCollectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? PhotoCollectionCell
      if let image = delegate?.displayLocalImageWithIndex?(self, index: currentIndex) {
        
        cell?.zoomImageScrollView.setLocalImage(image)
        
      } else {
        
        cell?.zoomImageScrollView.setImageUrl(delegate?.displayWebImageWithIndex?(self, index: currentIndex) ?? "", placeholderImage: delegate?.placeHolderImageWithIndex?(self, index: currentIndex), loadNow: true)
        
      }
    }
  }
  
  fileprivate func loadImageToMemory(withIndex index: Int) {
    
    DispatchQueue.global().async {
            
      guard let imageNum = self.delegate?.numberOfImage(self) else { return }
      
      guard index >= 0 && index < imageNum else { return }
      
      guard let imageUrl = self.delegate?.displayWebImageWithIndex?(self, index: index) else { return }
      
      SDImageCache.shared().imageFromCache(forKey: imageUrl)
      
    }
  }
}

extension WZPhotoBrowser: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate?.numberOfImage(self) ?? 0
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionCell
    
    cell.zoomImageScrollView.addImageTarget(self, action: #selector(WZPhotoBrowser.onClickPhoto))
    cell.padding = padding
    cell.zoomImageScrollView.doubleTapMagnify = doubleTapMagnify
    
    let loadNow = !(isAnimate && !isDidShow && currentIndex == indexPath.row)
    
    if let image = delegate?.displayLocalImageWithIndex?(self, index: indexPath.row) {
      
      cell.setLocalImage(image)
      
    } else {
      
      cell.setImageUrl(delegate?.displayWebImageWithIndex?(self, index: indexPath.row) ?? "", placeholderImage: delegate?.placeHolderImageWithIndex?(self, index: indexPath.row), loadNow: loadNow)
      
      loadImageToMemory(withIndex: indexPath.row - 1)
      loadImageToMemory(withIndex: indexPath.row + 1)
      
    }
    
    return cell
    
  }
}

extension WZPhotoBrowser: UICollectionViewDelegateFlowLayout {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    //更新currentIndex
    let cellPoint = view.convert(mainCollectionView.center, to: mainCollectionView)
    
    guard let showPhotoIndex = mainCollectionView.indexPathForItem(at: cellPoint)?.row else { return }
    guard currentIndex != showPhotoIndex else { return }
    
    currentIndex = showPhotoIndex
  }
}

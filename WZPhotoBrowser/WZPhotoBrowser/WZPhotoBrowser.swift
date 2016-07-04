//
//  WZPhotoBrowser.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/2.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

protocol WZPhotoBrowserAnimatedTransitionDataSource: NSObjectProtocol {
  
  //如果index为nil则返回当前点击的即将跳转图片浏器的图片的frame
  func getImageViewFrameInScreenWith(index: Int?) -> CGRect?
  
  func getImageForAnimation() -> UIImage?
  
}

@objc protocol WZPhotoBrowserAnimatedTransitionDelegate: NSObjectProtocol {
  
  optional func animatedTransitionBeginPresentViewController(animatedImageView: UIImageView)
  
  optional func animateInBlockWhenPresentingViewController(animatedImageView: UIImageView) -> ()->Void
  
  optional func animatedTransitionEndPresentViewController(animatedImageView: UIImageView)
  
  optional func animatedTransitionBeginDismissViewController(animatedImageView: UIImageView)
  
  optional func animateBlockWhenDismissingViewController(animatedImageView: UIImageView) -> ()->Void
  
  optional func animatedTransitionEndDismissViewController(animatedImageView: UIImageView)
  
}

@objc protocol WZPhotoBrowserDelegate: NSObjectProtocol {
  
  //图片总数
  func numberOfImage(photoBrowser: WZPhotoBrowser) -> Int
  //加载网络图片
  func displayWebImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> String
  //加载本地图片，较网络图片优先判断
  optional func displayLocalImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> UIImage?
  //加载网络图片时的占位图片
  optional func placeHolderImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> UIImage?
  //第一次进入时显示的图片index，默认为0
  optional func firstDisplayIndex(photoBrowser: WZPhotoBrowser) -> Int
  
}

class WZPhotoBrowser: UIViewController {
  
  private var mainCollectionView: UICollectionView!
  private var prepareShowCell: PhotoCollectionCell!
  
  weak var delegate: WZPhotoBrowserDelegate?
  var quitBlock: (() -> Void)?
  private(set) var currentIndex: Int = 0 {
    didSet{
      photoDidChange()
    }
  }
  var isAnimate = false //用于设置是否经过动画跳转来 ，由PhotoTransitionPushAnimation设置
  var isDidShow = false //用于标记次VC是否已经呈现
  var isHideStatusBar = false
  
  let IDENTIFIER_IMAGE_CELL = "ZoomImageCell"
  let padding: CGFloat = 6
  
  init(delegate: WZPhotoBrowserDelegate, quitBlock: (() -> Void)? = nil) {
    
    self.delegate = delegate
    self.quitBlock = quitBlock
    super.init(nibName: nil, bundle: nil)
  }
  
  deinit {
    print("deinit")
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initView()
    
  }
  
  override func viewWillAppear(animated: Bool) {
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
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    isHideStatusBar = true
    setNeedsStatusBarAppearanceUpdate()
  }
  
  override func viewWillLayoutSubviews() {
    prepareShowCell = mainCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: currentIndex, inSection: 0)) as? PhotoCollectionCell
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    hideNavigationBar()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return isHideStatusBar
  }
  
  private func initView() {
    
    automaticallyAdjustsScrollViewInsets = false
    view.backgroundColor = UIColor.blackColor()
    view.clipsToBounds = true
    
    initMainTableView()
    
  }
  
  private func initMainTableView() {
    
    let mainCollectionViewFrame = CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height)
    
    let mainCollectionViewLayout = UICollectionViewFlowLayout()
    mainCollectionViewLayout.itemSize = mainCollectionViewFrame.size
    mainCollectionViewLayout.minimumInteritemSpacing = 0
    mainCollectionViewLayout.minimumLineSpacing = 0
    mainCollectionViewLayout.scrollDirection = .Horizontal
    
    mainCollectionView = UICollectionView(frame: mainCollectionViewFrame, collectionViewLayout: mainCollectionViewLayout)
    mainCollectionView.delegate = self
    mainCollectionView.dataSource = self
    mainCollectionView.pagingEnabled = true
    mainCollectionView.backgroundColor = UIColor.blackColor()
    mainCollectionView.registerClass(PhotoCollectionCell.self, forCellWithReuseIdentifier: "PhotoCollectionCell")
    view.addSubview(mainCollectionView)
    
  }
  
  /**
   收起navigationbar 暂不用
   */
  private func hideNavigationBar() {
    
    if navigationController == nil {
      return
    }
    
    let isHidden = navigationController!.navigationBarHidden
    navigationController!.setNavigationBarHidden(!isHidden, animated: true)
    //    UIApplication.sharedApplication().setStatusBarStyle(isHidden ? .Default : .LightContent, animated: false)
    
    
  }
  
  func moveToPhoto(with index: Int) {
    
    mainCollectionView.setContentOffset(CGPoint(x: CGFloat(index) * CGRectGetWidth(mainCollectionView.frame), y: 0), animated: false)
    
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
    
    let cell = (mainCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: currentIndex, inSection: 0)) as? PhotoCollectionCell) ?? prepareShowCell
    return cell?.zoomImageScrollView.getImageRectForAnimation() ?? CGRectZero
  }
  
  //for transitionAnimation
  func setMainTableViewHiddenForAnimation(isHidden: Bool) {
    mainCollectionView.hidden = isHidden
  }
  
  //for transitionAnimation dismiss
  func getCurrentDisplayImage() -> UIImage? {
    
    let cell = mainCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: currentIndex, inSection: 0)) as? PhotoCollectionCell
    return cell?.zoomImageScrollView.getImageForAnimation()
  }
  
  //for transitionAnimation presnet
  func completePresent() {
    
    if isAnimate {
      
      isDidShow = true
      let cell = mainCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: currentIndex, inSection: 0)) as? PhotoCollectionCell
      if let image = delegate?.displayLocalImageWithIndex?(self, index: currentIndex) {
        
        cell?.zoomImageScrollView.setLocalImage(image)
        
      } else {
        
        cell?.zoomImageScrollView.setImageUrl(delegate?.displayWebImageWithIndex(self, index: currentIndex) ?? "", placeholderImage: delegate?.placeHolderImageWithIndex?(self, index: currentIndex), loadNow: true)
        
      }
      
    }
  }
}

extension WZPhotoBrowser: UICollectionViewDataSource {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate?.numberOfImage(self) ?? 0
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionCell", forIndexPath: indexPath) as! PhotoCollectionCell
    
    cell.zoomImageScrollView.addImageTarget(self, action: #selector(WZPhotoBrowser.onClickPhoto))
    
    cell.padding = padding
    
    let loadNow = !(isAnimate && !isDidShow && currentIndex == indexPath.row)
    
    if let image = delegate?.displayLocalImageWithIndex?(self, index: indexPath.row) {
      
      cell.zoomImageScrollView.setLocalImage(image)
      
    } else {
      
      cell.zoomImageScrollView.setImageUrl(delegate?.displayWebImageWithIndex(self, index: indexPath.row) ?? "", placeholderImage: delegate?.placeHolderImageWithIndex?(self, index: indexPath.row), loadNow: loadNow)
      
    }
    
    return cell
    
  }
}

extension WZPhotoBrowser: UICollectionViewDelegateFlowLayout {
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    
    //更新currentIndex
    let cellPoint = view.convertPoint(mainCollectionView.center, toView: mainCollectionView)
    let showPhotoIndex = mainCollectionView.indexPathForItemAtPoint(cellPoint)
    
    if let _showPhotoIndex = showPhotoIndex where currentIndex != _showPhotoIndex {
      currentIndex = showPhotoIndex!.row
    }
    
  }
  
}

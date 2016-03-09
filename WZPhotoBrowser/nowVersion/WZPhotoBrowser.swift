//
//  WZPhotoBrowser.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/2.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit

protocol WZPhotoBrowserAnimatedTransition: NSObjectProtocol {
  
  //如果index为nil则返回当前点击的即将跳转图片浏器的图片的frame
  func getImageViewFrameInParentViewWith(index: Int?) -> CGRect?
  
  func getImageForAnimation() -> UIImage?
  
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
  
  private var mainTableView: HTableViewForPhoto!
  private var thumbCollectionView: UICollectionView!
  private var borderView: UIImageView!
  
  private var thumbWidth: CGFloat!
  private var isDraggingMainView = true
  private var isMoveThumb = false //当图片数量少于thumbNum时，thumbCollectionView不会移动
  private var isClickThumb = false
  
  var delegate: WZPhotoBrowserDelegate
  var quitBlock: (() -> Void)?
  var selectCellIndex: Int = 0 {
    didSet{
      photoDidChange()
    }
  }
  var isAnimate = false //用于设置是否经过动画跳转来 ，由PhotoTransitionPushAnimation设置
  var isDidShow = false //用于标记次VC是否已经呈现
  var isShowThumb = false
  //主图中每移动一张照片，缩略图需要移动的距离
  var distancePerMainPhoto: CGFloat!
  
  let IDENTIFIER_IMAGE_CELL = "ZoomImageCell"
  let IDENTIFIER_THUMB_CELL = "ThumbCollectionViewCell"
  let thumbNum: Float = 5.5
  let padding: CGFloat = 6
  let borderWidth: CGFloat = 4
  let cleardeviation: CGFloat = 0
  let contentOffsetDuration: NSTimeInterval = 0.3
  
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
  
    initView()
    
    isMoveThumb = delegate.numberOfImage(self) > Int(thumbNum)
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    mainTableView.moveToPage(delegate.firstDisplayIndex?(self) ?? 0)
    
    //当默认显示第0张时，selectCellIndex不会被赋值，需要手动赋值，以便调用photoDidChange
    if delegate.firstDisplayIndex?(self) != nil && (delegate.firstDisplayIndex?(self))! == 0 {
      selectCellIndex = 0
    }

    hideNavigationBar()
  }
  
  override func viewDidAppear(animated: Bool) {
    
    distancePerMainPhoto = (thumbCollectionView.contentSize.width - thumbCollectionView.frame.width) / CGFloat(delegate.numberOfImage(self) - 1)
    scrollViewDidScroll(thumbCollectionView)

  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    hideNavigationBar()
  }
  
  private func initView() {
    automaticallyAdjustsScrollViewInsets = false
    view.backgroundColor = UIColor.blackColor()
    view.clipsToBounds = true
    
    initMainTableView()
    
    initthumbCollectionView()
    
    initBoardView()
    
  }
  
  private func initMainTableView() {
    
    mainTableView = HTableViewForPhoto(frame: CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height))
    mainTableView.delegateForHTableView = self
    mainTableView.dataSource = self
    mainTableView.pagingEnabled = true
    mainTableView.backgroundColor = UIColor.blackColor()
    view.addSubview(mainTableView)
    
  }
  
  private func initthumbCollectionView() {
    
    thumbWidth = view.frame.width / CGFloat(thumbNum)
    
    let collectionViewLayout = UICollectionViewFlowLayout()
    collectionViewLayout.minimumInteritemSpacing = 0
    collectionViewLayout.minimumLineSpacing = 0
    collectionViewLayout.scrollDirection = .Horizontal

    thumbCollectionView = UICollectionView(frame: CGRect(x: 0, y: mainTableView.bounds.height - thumbWidth, width: view.bounds.width, height: thumbWidth), collectionViewLayout: collectionViewLayout)
    thumbCollectionView.hidden = !isShowThumb
    thumbCollectionView.decelerationRate = 0
    thumbCollectionView.delegate = self
    thumbCollectionView.dataSource = self
    thumbCollectionView.registerNib(UINib(nibName: IDENTIFIER_THUMB_CELL, bundle: nil), forCellWithReuseIdentifier: IDENTIFIER_THUMB_CELL)
    thumbCollectionView.backgroundColor = UIColor.hexStringToColor("000000", alpha: 0.5)
    thumbCollectionView.pagingEnabled = false
    thumbCollectionView.showsHorizontalScrollIndicator = false
    view.addSubview(thumbCollectionView)
  }
  
  private func initBoardView() {
    
    borderView = UIImageView(frame: CGRect(x: borderWidth / 2 - cleardeviation, y: thumbCollectionView.frame.minY , width: thumbWidth - borderWidth + cleardeviation * 2, height: thumbWidth))
    borderView.hidden = !isShowThumb
    borderView.image = UIImage(named: "img_kung")
    borderView.userInteractionEnabled = false
    view.addSubview(borderView)
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
    
  }
  
  //调整缩略图的偏移
  private func adjustThumOffset(offsetX: CGFloat) {
    
    //通过四舍五入计算需要移动到哪一个照片的位置
    let finalIndex = lroundf(Float(offsetX / distancePerMainPhoto))
    
    UIView.animateWithDuration(contentOffsetDuration, animations: { () -> Void in
      
      self.thumbCollectionView.setContentOffset(CGPoint(x: CGFloat(finalIndex) * self.distancePerMainPhoto, y: 0), animated: false)
      
      }) { (finish) -> Void in
        
        //校正零点几像素的偏差
        //        self.moveBorderViewTo(finalIndex)
        
    }
    
    
  }
  
  private func moveBorderView(progress: CGFloat) {
    //当图片数量少于thumbNum时，borderView不会滑到头
    let rangeWidth = isMoveThumb == true ? view.frame.width : thumbCollectionView.contentSize.width
    let borderViewOffset = progress * (rangeWidth - borderWidth - borderView.frame.width) - cleardeviation
    
    borderView.frame = CGRect(x: borderViewOffset + borderWidth / 2, y: borderView.frame.minY, width: borderView.frame.width, height: borderView.frame.height)
  }
  
  //直接移动边框到某位置
  private func moveBorderViewTo(didSelectRowAtIndex: Int) {
    
    let cell = thumbCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: didSelectRowAtIndex, inSection: 0))!
    var cellPointInView = view.convertPoint(cell.frame.origin, fromView: thumbCollectionView)
    cellPointInView.x += borderWidth / 2
    
    UIView.animateWithDuration(contentOffsetDuration, animations: { () -> Void in
      
      self.borderView.frame.origin = CGPoint(x: cellPointInView.x, y: self.borderView.frame.origin.y)
      
      }) { (finish) -> Void in
        
    }
  }
  
  func onClickPhoto() {
    
    quitBlock?()
    
  }
  
  func photoDidChange() {

  }
  
  //for transitionAnimation
  func getCurrentDisplayImageSize() -> CGSize {
    
    let cell = mainTableView.cellForRowAtIndex(selectCellIndex)
    return cell.getImageSize()
  }
  
  //for transitionAnimation
  func setMainTableViewHiddenForAnimation(isHidden: Bool) {
    mainTableView.hidden = isHidden
  }
  
  //for transitionAnimation dismiss
  func getCurrentDisplayImage() -> UIImage? {
    
    let cell = mainTableView.cellForRowAtIndex(selectCellIndex)
    return cell.getImage()
  }

  //for transitionAnimation presnet
  func completePresent() {
    
    if isAnimate {
      
      isDidShow = true
      let cell = mainTableView.cellForRowAtIndex(selectCellIndex)
      
      if let image = delegate.displayLocalImageWithIndex?(self, index: selectCellIndex) {
        
        cell.setLocalImage(image)
        
      } else {
        
        cell.setImageUrl(delegate.displayWebImageWithIndex(self, index: selectCellIndex), placeholderImage: delegate.placeHolderImageWithIndex?(self, index: selectCellIndex), loadNow: true)
        
      }
      
    }
  }
}

extension WZPhotoBrowser: HTableViewForPhotoDataSource {
  
  func numberOfColumnsForPhoto(hTableView: HTableViewForPhoto) -> Int{
    return delegate.numberOfImage(self)
  }
  
  func hTableViewForPhoto(hTableView: HTableViewForPhoto, cellForColumnAtIndex index: Int) -> ZoomImageScrollView{
    var cell = hTableView.dequeueReusableCellWithIdentifier(IDENTIFIER_IMAGE_CELL)
    if cell == nil {
      cell = ZoomImageScrollView(reuseIdentifier: IDENTIFIER_IMAGE_CELL)
      cell!.addImageTarget(self, action: Selector("onClickPhoto"))
    }
    
    cell!.frame = mainTableView.frame
    cell!.padding = padding
    
    let loadNow = !(isAnimate && !isDidShow && selectCellIndex == index)
    
    if let image = delegate.displayLocalImageWithIndex?(self, index: index) {
      
      cell!.setLocalImage(image)

    } else {
      
      cell!.setImageUrl(delegate.displayWebImageWithIndex(self, index: index), placeholderImage: delegate.placeHolderImageWithIndex?(self, index: index), loadNow: loadNow)

    }

    return cell!
  }
}

extension WZPhotoBrowser: UICollectionViewDataSource {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate.numberOfImage(self)
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(IDENTIFIER_THUMB_CELL, forIndexPath: indexPath) as! ThumbCollectionViewCell
    
    cell.setBorderWidth(borderWidth / 2)

    if let image = delegate.displayLocalImageWithIndex?(self, index: indexPath.row) {
      
      cell.setImageWith(image: image)
      
    } else {
      
      cell.setImageWith(imgUrl: delegate.displayWebImageWithIndex(self, index: indexPath.row))

      
    }
    
    
    return cell
    
  }
}

extension WZPhotoBrowser: HTableViewForPhotoDelegate {
  
  func hTableViewForPhoto(hTableView: HTableViewForPhoto, widthForColumnAtIndex index: Int) -> CGFloat{
    return mainTableView.frame.width
  }
  
  func hTableViewForPhoto(hTableView: HTableViewForPhoto, didSelectRowAtIndex: Int) {
    
    onClickPhoto()
    
  }
  
  func hTableViewForPhotoDidScroll(hTableViewForPhoto: HTableViewForPhoto) {
    
    //更新selectCellIndex
    let cellPoint = view.convertPoint(hTableViewForPhoto.center, toView: mainTableView)
    let showPhotoIndex = mainTableView.indexForRowAtPoint(cellPoint)
    
    guard showPhotoIndex != nil else {
      return
    }
    
    if selectCellIndex != showPhotoIndex! {
      selectCellIndex = showPhotoIndex!
    }

    //只有当拖拽主图时才，缩略图才会移动，不然拖动缩略图时主图移动，又回使缩略图一起移动
    if !isDraggingMainView {
      return
    }
    
    var progress = hTableViewForPhoto.contentOffset.x / (hTableViewForPhoto.contentSize.width / CGFloat(delegate.numberOfImage(self)) * CGFloat(delegate.numberOfImage(self) - 1))
    
    progress = progress > 1.0 ? 1.0 : progress
    progress = progress < 0.0 ? 0.0 : progress
    
    moveBorderView(progress)
    
    if isMoveThumb {
      
      let thumbOffset = progress * (thumbCollectionView.contentSize.width - view.frame.width)
      thumbCollectionView.setContentOffset(CGPoint(x: thumbOffset, y: 0), animated: false)
      
    }
  }
  
  func hTableViewForPhotoWillBeginDragging(hTableViewForPhoto: HTableViewForPhoto) {
    
    isDraggingMainView = true
    isClickThumb = false
    
  }
  
  func hTableViewForPhotoDidEndDecelerating(hTableViewForPhoto: HTableViewForPhoto) {
    
//    let cellPoint = view.convertPoint(hTableViewForPhoto.center, toView: mainTableView)
//    let showPhotoIndex = mainTableView.indexForRowAtPoint(cellPoint)
//    selectCellIndex = showPhotoIndex ?? 0
    
    //校正零点几像素的偏差
    //    moveBorderViewTo(selectCellIndex)
    
  }
}



extension WZPhotoBrowser: UICollectionViewDelegateFlowLayout {
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return CGSize(width: thumbWidth, height: thumbWidth)
  }
  
  func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    
    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x + 1, y: 0), animated: false)
    
    isDraggingMainView = false
    isClickThumb = false
    
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
    isClickThumb = true
    
    //防止滑动maintableview时thunmTableView 一起动
    isDraggingMainView = false
    
    mainTableView.moveToPage(indexPath.row)
    
    selectCellIndex = indexPath.row
    
    isDraggingMainView = true
    
    if isMoveThumb {
      
      self.thumbCollectionView.setContentOffset(CGPoint(x: self.distancePerMainPhoto * CGFloat(self.selectCellIndex), y: 0), animated: true)
      
    } else {
      
      moveBorderViewTo(indexPath.row)
      
    }
    
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    
    var progress = scrollView.contentOffset.x / (thumbCollectionView.contentSize.width - view.frame.width)
    
    progress = progress > 1.0 ? 1.0 : progress
    progress = progress < 0.0 ? 0.0 : progress
    
    //边框随缩略图移动
    
    if (isMoveThumb && !isDraggingMainView) || isClickThumb {
      
      moveBorderView(progress)
      
    }
    
    if isDraggingMainView {
      return
    }
    
    let mainPhotoShouldOffset = progress * (mainTableView.contentSize.width / CGFloat(delegate.numberOfImage(self)) * CGFloat(delegate.numberOfImage(self) - 1))
    
    //当移动了半张图片的距离是就显示下张图片
    if abs(mainPhotoShouldOffset - mainTableView.contentOffset.x) > mainTableView.frame.width / 2 {
      
      let offset = mainPhotoShouldOffset > mainTableView.contentOffset.x ? mainTableView.frame.width : -mainTableView.frame.width
      mainTableView.setContentOffset(CGPoint(x: mainTableView.contentOffset.x + offset, y: 0), animated: false)
      
    }
    
  }
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    
    let offsetX = scrollView.contentOffset.x
    adjustThumOffset(offsetX)
    
  }
  
  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    
    if decelerate {
      return
    }
    
    let offsetX = scrollView.contentOffset.x
    adjustThumOffset(offsetX)
    
  }
  
  
}

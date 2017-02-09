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
  func getImageViewFrameInScreenWith(index: Int?) -> CGRect?
  
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
  
  weak var delegate: WZPhotoBrowserDelegate?
  var quitBlock: (() -> Void)?
  private(set) var currentIndex: Int = 0 {
    didSet{
      photoDidChange()
    }
  }
  var isAnimate = false //用于设置是否经过动画跳转来 ，由PhotoTransitionPushAnimation设置
  var isDidShow = false //用于标记次VC是否已经呈现
  
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
    
    initView()
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    mainTableView.moveToPage(delegate?.firstDisplayIndex?(self) ?? 0)
    
    //当默认显示第0张时，currentIndex不会被赋值，需要手动赋值，以便调用photoDidChange
    if delegate?.firstDisplayIndex?(self) != nil && (delegate?.firstDisplayIndex?(self))! == 0 {
      currentIndex = 0
    }
    
    hideNavigationBar()
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
    
  }
  
  private func initMainTableView() {
    
    mainTableView = HTableViewForPhoto(frame: CGRect(x: -padding, y: view.bounds.minY, width: view.bounds.width + padding * 2, height: view.bounds.height))
    mainTableView.delegateForHTableView = self
    mainTableView.dataSource = self
    mainTableView.pagingEnabled = true
    mainTableView.backgroundColor = UIColor.blackColor()
    view.addSubview(mainTableView)
    
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
    UIApplication.sharedApplication().setStatusBarStyle(isHidden ? .Default : .LightContent, animated: false)

  }
  
  func onClickPhoto() {
    
    quitBlock?()
    quitBlock = nil
  }
  
  func photoDidChange() {
    
  }
  
  func reload() {
  
    mainTableView.reload()
    mainTableView.moveToPage(delegate?.firstDisplayIndex?(self) ?? 0)
  }
  
  //for transitionAnimation
  func getCurrentDisplayImageSize() -> CGSize {
    
    let cell = mainTableView.cellForRowAtIndex(currentIndex)
    return cell?.getImageSize() ?? CGSizeZero
  }
  
  //for transitionAnimation
  func setMainTableViewHiddenForAnimation(isHidden: Bool) {
    mainTableView.hidden = isHidden
  }
  
  //for transitionAnimation dismiss
  func getCurrentDisplayImage() -> UIImage? {
    
    let cell = mainTableView.cellForRowAtIndex(currentIndex)
    return cell?.getImage()
  }
  
  //for transitionAnimation presnet
  func completePresent() {
    
    if isAnimate {
      
      isDidShow = true
      let cell = mainTableView.cellForRowAtIndex(currentIndex)
      
      if let image = delegate?.displayLocalImageWithIndex?(self, index: currentIndex) {
        
        cell?.setLocalImage(image)
        
      } else {
        
        cell?.setImageUrl(delegate?.displayWebImageWithIndex(self, index: currentIndex) ?? "", placeholderImage: delegate?.placeHolderImageWithIndex?(self, index: currentIndex), loadNow: true)
        
      }
      
    }
  }
}

extension WZPhotoBrowser: HTableViewForPhotoDataSource {
  
  func numberOfColumnsForPhoto(hTableView: HTableViewForPhoto) -> Int{
    return delegate?.numberOfImage(self) ?? 0
  }
  
  func hTableViewForPhoto(hTableView: HTableViewForPhoto, cellForColumnAtIndex index: Int) -> ZoomImageScrollView{
    var cell = hTableView.dequeueReusableCellWithIdentifier(IDENTIFIER_IMAGE_CELL)
    if cell == nil {
      cell = ZoomImageScrollView(reuseIdentifier: IDENTIFIER_IMAGE_CELL)
      cell!.addImageTarget(self, action: #selector(WZPhotoBrowser.onClickPhoto))
    }
    
    cell!.frame = mainTableView.frame
    cell!.padding = padding
    
    let loadNow = !(isAnimate && !isDidShow && currentIndex == index)
    
    if let image = delegate?.displayLocalImageWithIndex?(self, index: index) {
      
      cell!.setLocalImage(image)
      
    } else {
      
      cell!.setImageUrl(delegate?.displayWebImageWithIndex(self, index: index) ?? "", placeholderImage: delegate?.placeHolderImageWithIndex?(self, index: index), loadNow: loadNow)
      
    }
    
    return cell!
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
    
    //更新currentIndex
    let cellPoint = view.convertPoint(hTableViewForPhoto.center, toView: mainTableView)
    let showPhotoIndex = mainTableView.indexForRowAtPoint(cellPoint)
    
    guard showPhotoIndex != nil else {
      return
    }
    
    if currentIndex != showPhotoIndex! {
      currentIndex = showPhotoIndex!
    }

  }
}


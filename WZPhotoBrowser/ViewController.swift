//
//  ViewController.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/1.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
  
  var button: UIButton!
  var selectImageIndex: Int!
  var slider: UISlider!
  var imageWidth: CGFloat!
  var imageStoreUrlList: [String] = [
    "http://image1.yuanfenba.net/uploads/oss/photo/201511/16/14361140059.jpg",
    "http://image1.yuanfenba.net/uploads/oss/photo/201511/19/17164875104.jpg",
    "http://image1.yuanfenba.net/uploads/oss/dynamic/201511/25/23171018488.jpg",
    "http://www.feizl.com/upload2007/2010_09/100911130437041.jpg",
//    "image1",
    "http://www.th7.cn/d/file/p/2014/05/26/0663b0489efeb590a78e8aba16e5040a.jpg",
    "http://g.hiphotos.baidu.com/album/pic/item/cf1b9d16fdfaaf51b530fc868e5494eef01f7a33.jpg?psign=b530fc868e5494eef01f3a292df5e0fe9825bc315c605e0b",
    "http://image.tianjimedia.com/uploadImages/2014/103/20/9QFI1QR41K5J.jpg",
    "http://www.th7.cn/d/file/p/2014/01/28/34c61c2dc4bab0f0570a26ee628bdf74.jpg",
    "http://www.bz55.com/uploads/allimg/130302/1-130302094042.jpg",
    "http://d.3987.com/qcsnngz_140703/002.jpg",
    "http://image.tianjimedia.com/uploadImages/2014/127/39/GA3WLSKVW5SR.jpg",
    "http://fc.topit.me/c/5e/dd/11305252553dddd5eco.jpg",
    "http://r.photo.store.qq.com/psb?/V13LH3PA3wo6Vo/PjU9yTKcQiEa.fZdWv2uebIToQkVqs0yaXy3mNUTCFw%21/o/dJYjcpSwGAAA&bo=wwOAAkAGJwQBAAA%21",
    "http://img5.aili.com/201404/25/1398406512_51645900.jpg",
    "http://images.ccoo.cn/bbs/2010818/201081814532688.jpg",
    "http://www.beihaiting.com/uploads/allimg/140919/10723-140919213430591.jpg"
  ]
  
  var imageUrlList: [String] = []
  var collectionView: UICollectionView!
  var thumbnailImageDic: [String: UIImage] = [:]
  var identifierCell = "VisitedMeCollectionViewCell"
  let vSpace: CGFloat = 10
  let hSpace: CGFloat = 10
  let numOfCol = 4
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "clear cache", style: .Plain, target: self, action: #selector(ViewController.onClearCache))
    
    imageUrlList = Array(imageStoreUrlList[0..<imageStoreUrlList.count])
    
    initView()
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
//    navigationController?.delegate = self
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func onClearCache() {
    
    SDImageCache.sharedImageCache().cleanDisk()
    SDImageCache.sharedImageCache().clearDisk()
    SDImageCache.sharedImageCache().clearMemory()
    
  }
  
  func initView(){
    
    title = "PhotoBrowser"
    
    view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    
    let layout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.backgroundColor = UIColor.purpleColor()
    collectionView.registerNib(UINib(nibName: identifierCell, bundle: nil), forCellWithReuseIdentifier: identifierCell)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    
    slider = UISlider(frame: CGRect(x: 10, y: 500, width: view.frame.width - 20, height: 10))
    slider.addTarget(self, action: #selector(ViewController.changeImageCount(_:)), forControlEvents: .ValueChanged)
    slider.value = Float(imageUrlList.count) / Float(imageStoreUrlList.count)
    
    view.addSubview(collectionView)
    view.addSubview(slider)

    UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)

  }
  
  func changeImageCount(sender: UISlider) {
    let imageCount = Int(sender.value * Float(imageStoreUrlList.count))
    
    imageUrlList = Array(imageStoreUrlList[0..<imageCount])
    collectionView.reloadData()
  }
  
  
  func showPhotoBrowser() {
    let photoBrowser = WZPhotoBrowser(delegate: self){ [weak self] in
      self?.dismissViewControllerAnimated(true, completion: nil)
    }
    photoBrowser.isAnimate = true
    photoBrowser.transitioningDelegate = self
    photoBrowser.isShowThumb = true
    presentViewController(photoBrowser, animated: true, completion: nil)
  }

}

extension ViewController: WZPhotoBrowserDelegate {
  func numberOfImage(photoBrowser: WZPhotoBrowser) -> Int {
    return imageUrlList.count
  }
  func displayWebImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> String {
    return imageUrlList[index]
  }
  
  func firstDisplayIndex(photoBrowser: WZPhotoBrowser) -> Int {
    return selectImageIndex
  }
  
  func placeHolderImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> UIImage? {
    return thumbnailImageDic[imageUrlList[index]]
  }
  
//  func displayLocalImageWithIndex(photoBrowser: WZPhotoBrowser, index: Int) -> UIImage? {
//    if index == 4 {
//      return UIImage(named: "image1")
//    } else {
//      return nil
//    }
//  }
}

extension ViewController: UICollectionViewDataSource {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageUrlList.count
  }
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierCell, forIndexPath: indexPath) as! VisitedMeCollectionViewCell
    
    cell.avatarImageView.sd_setImageWithURL(NSURL(string: imageUrlList[indexPath.row])) { (image, ErrorType, type, url) -> Void in
      
      if  image == nil {
        cell.avatarImageView.image = UIImage(named: url.absoluteString)
      }
      
      self.thumbnailImageDic[self.imageUrlList[indexPath.row]] = image ?? UIImage(named: url.absoluteString)

    }
    
//    cell.avatarImageView.imageWithUrl(imageUrlList[indexPath.row], size: CGSize(width: imageWidth, height: imageWidth), imageStyle: .OriginScale, plachholderImage: nil) { (image) -> Void in
//      
//      self.thumbnailImageDic[self.imageUrlList[indexPath.row]] = image
//
//    }

    return cell
  }
  
}

extension ViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    
    var width: CGFloat = 0
    width = (view.frame.width - CGFloat(numOfCol - 1) * hSpace) / CGFloat(numOfCol)
    
    imageWidth = width
    let size = CGSize(width: width, height: width)
    
    return size
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
    return vSpace
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
    return 0
  }
  
}

extension ViewController: UICollectionViewDelegate {
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    selectImageIndex = indexPath.row
    showPhotoBrowser()
  }
  
}


extension ViewController: UIViewControllerTransitioningDelegate {
  
  func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    return PhotoTransitionPresentAnimation(showVC: self)
  }

  func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?{
    return PhotoTransitionDismissAnimation(showVC: self)
  }

}

extension ViewController: WZPhotoBrowserAnimatedTransition {
  
  func getImageViewFrameInScreenWith(index: Int?) -> CGRect? {
    
    if let imageItem = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index ?? selectImageIndex, inSection: 0)) {
      
      let imagePositionInView = collectionView.convertRect(imageItem.frame, toView: nil)
      
      return imagePositionInView
    }

    return nil
  }
  
  func getImageForAnimation() -> UIImage? {
    
    return thumbnailImageDic[imageUrlList[selectImageIndex]]

  }
}
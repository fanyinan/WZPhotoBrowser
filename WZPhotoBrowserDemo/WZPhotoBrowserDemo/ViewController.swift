//
//  ViewController.swift
//  WZPhotoBrowser
//
//  Created by 范祎楠 on 15/9/1.
//  Copyright © 2015年 范祎楠. All rights reserved.
//

import UIKit
import SDWebImage

class ViewController: UIViewController {
  
  var button: UIButton!
  var selectImageIndex: Int!
  var slider: UISlider!
  var imageWidth: CGFloat!
  var imageStoreUrlList: [String] = [
    "http://avatar.csdn.net/5/0/E/2_tangxiaoyin.jpg",
    "http://www.qq1234.org/uploads/allimg/150709/8_150709172502_8.jpg",
    "http://wenwen.soso.com/p/20100824/20100824165300-1042703649.jpg",
    "http://www.feizl.com/upload2007/2014_06/1406251642203323.jpg",
    "http://image1.yuanfenba.net/uploads/oss/photo/201511/16/14361140059.jpg",
    "http://image1.yuanfenba.net/uploads/oss/photo/201511/19/17164875104.jpg",
    "http://image1.yuanfenba.net/uploads/oss/dynamic/201511/25/23171018488.jpg",
    "http://www.feizl.com/upload2007/2010_09/100911130437041.jpg",
    "http://www.th7.cn/d/file/p/2014/05/26/0663b0489efeb590a78e8aba16e5040a.jpg",
    "http://g.hiphotos.baidu.com/album/pic/item/cf1b9d16fdfaaf51b530fc868e5494eef01f7a33.jpg?psign=b530fc868e5494eef01f3a292df5e0fe9825bc315c605e0b",
    "http://image.tianjimedia.com/uploadImages/2014/103/20/9QFI1QR41K5J.jpg",
    "http://www.th7.cn/d/file/p/2014/01/28/34c61c2dc4bab0f0570a26ee628bdf74.jpg",
    "http://www.bz55.com/uploads/allimg/130302/1-130302094042.jpg",
    "http://image.tianjimedia.com/uploadImages/2014/127/39/GA3WLSKVW5SR.jpg",
    "http://fc.topit.me/c/5e/dd/11305252553dddd5eco.jpg",
    "http://r.photo.store.qq.com/psb?/V13LH3PA3wo6Vo/PjU9yTKcQiEa.fZdWv2uebIToQkVqs0yaXy3mNUTCFw%21/o/dJYjcpSwGAAA&bo=wwOAAkAGJwQBAAA%21",
    "http://img5.aili.com/201404/25/1398406512_51645900.jpg",
    "http://images.ccoo.cn/bbs/2010818/201081814532688.jpg",
    "http://www.beihaiting.com/uploads/allimg/140919/10723-140919213430591.jpg",
    "http://pics.sc.chinaz.com/Files/pic/faces/4407/13.gif"
  ]
  
  var imageUrlList: [String] = []
  var collectionView: UICollectionView!
  var thumbnailImageDic: [String: UIImage] = [:]
  var identifierCell = "ThumbCell"
  let vSpace: CGFloat = 10
  let hSpace: CGFloat = 10
  let numOfCol = 4
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "clear cache", style: .plain, target: self, action: #selector(ViewController.onClearCache))
    
    imageUrlList = Array(imageStoreUrlList[0..<imageStoreUrlList.count])
    
    initView()

  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func onClearCache() {
    
    SDImageCache.shared().clearMemory()
    SDImageCache.shared().clearDisk(onCompletion: nil)
    
  }
  
  func initView(){
    
    title = "PhotoBrowser"
    
    view.backgroundColor = UIColor.groupTableViewBackground
    
    let layout = UICollectionViewFlowLayout()
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
    collectionView.backgroundColor = UIColor.black
    collectionView.register(UINib(nibName: identifierCell, bundle: nil), forCellWithReuseIdentifier: identifierCell)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    slider = UISlider(frame: CGRect(x: 10, y: 500, width: view.frame.width - 20, height: 10))
    slider.addTarget(self, action: #selector(ViewController.changeImageCount(_:)), for: .valueChanged)
    slider.value = Float(imageUrlList.count) / Float(imageStoreUrlList.count)
    slider.autoresizingMask = [.flexibleWidth,.flexibleTopMargin]
    
    view.addSubview(collectionView)
    view.addSubview(slider)

    UIApplication.shared.setStatusBarHidden(true, with: .none)

  }
  
  func changeImageCount(_ sender: UISlider) {
    let imageCount = Int(sender.value * Float(imageStoreUrlList.count))
    
    imageUrlList = Array(imageStoreUrlList[0..<imageCount])
    collectionView.reloadData()
  }
  
  
  func showPhotoBrowser() {
    let photoBrowser = WZPhotoBrowser(delegate: self){ [weak self] in
      self?.dismiss(animated: true, completion: nil)
    }
    photoBrowser.isAnimate = true
    photoBrowser.doubleTapMagnify = true
    photoBrowser.transitioningDelegate = self
    present(photoBrowser, animated: true, completion: nil)
  }

}

extension ViewController: WZPhotoBrowserDelegate {
  
  func numberOfImage(_ photoBrowser: WZPhotoBrowser) -> Int {
    return imageUrlList.count
  }
  func displayWebImageWithIndex(_ photoBrowser: WZPhotoBrowser, index: Int) -> String {
    return imageUrlList[index]
  }
  
  func firstDisplayIndex(_ photoBrowser: WZPhotoBrowser) -> Int {
    return selectImageIndex
  }
  
  func placeHolderImageWithIndex(_ photoBrowser: WZPhotoBrowser, index: Int) -> UIImage? {
    return thumbnailImageDic[imageUrlList[index]]
  }
  
}

extension ViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageUrlList.count
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifierCell, for: indexPath) as! ThumbCell
    
    cell.avatarImageView.sd_setImage(with: URL(string: imageUrlList[indexPath.row]), placeholderImage: nil, options: [], completed: { (image, ErrorType, type, url) -> Void in
      
      self.thumbnailImageDic[self.imageUrlList[indexPath.row]] = image ?? UIImage(named: url!.absoluteString)
        
    })

    return cell
  }
  
}

extension ViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    var width: CGFloat = 0
    width = (view.frame.width - CGFloat(numOfCol - 1) * hSpace) / CGFloat(numOfCol)
    
    imageWidth = width
    let size = CGSize(width: width, height: width)
    
    return size
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return vSpace
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
}

extension ViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    selectImageIndex = indexPath.row
    showPhotoBrowser()
  }
  
}


extension ViewController: UIViewControllerTransitioningDelegate {
  
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    return PhotoTransitionPresentAnimation(showVC: self)
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?{
    return PhotoTransitionDismissAnimation(showVC: self)
  }

}

extension ViewController: WZPhotoBrowserAnimatedTransitionDataSource {
  
  func getImageViewFrameInScreenWith(_ index: Int?) -> CGRect? {
    
    if let imageItem = collectionView.cellForItem(at: IndexPath(row: index ?? selectImageIndex, section: 0)) {
      
      let imagePositionInView = collectionView.convert(imageItem.frame, to: nil)
      
      return imagePositionInView
    }

    return nil
  }
  
  func getImageForAnimation() -> UIImage? {
    
    return thumbnailImageDic[imageUrlList[selectImageIndex]]

  }
}

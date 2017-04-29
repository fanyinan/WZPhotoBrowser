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
    "http://image1.yuanfenba.net/uploads/oss/avatar/201703/22/1706308129.jpg",
    "http://image1.yuanfenba.net/uploads/oss/photo/201511/19/17164875104.jpg",
    "http://image1.yuanfenba.net/uploads/oss/dynamic/201511/25/23171018488.jpg",
    "http://image1.yuanfenba.net/uploads/oss/avatar/201704/05/1537466920.jpg",
    "http://image1.yuanfenba.net/uploads/oss/avatar/201608/02/17341194657.jpg",
    "http://image1.yuanfenba.net/uploads/oss/avatar/201608/03/11134237396.jpg",
    "http://r.photo.store.qq.com/psb?/V13LH3PA3wo6Vo/PjU9yTKcQiEa.fZdWv2uebIToQkVqs0yaXy3mNUTCFw%21/o/dJYjcpSwGAAA&bo=wwOAAkAGJwQBAAA%21",
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
    
    let thumbImageURL = imageUrlList[indexPath.row] + "@1e_\(Int(cell.avatarImageView.frame.width))w_\(Int(cell.avatarImageView.frame.width))h_0c_0i_1o_90Q_1x.png"
    cell.avatarImageView.sd_setImage(with: URL(string: thumbImageURL), placeholderImage: nil, options: [], completed: { (image, ErrorType, type, url) -> Void in
      
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

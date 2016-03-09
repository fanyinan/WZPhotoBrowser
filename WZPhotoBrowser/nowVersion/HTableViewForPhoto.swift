//
//  HTableView.swift
//  HorizontalTableView
//
//  Created by 范祎楠 on 15/5/30.
//  Copyright (c) 2015年 范祎楠. All rights reserved.
//

import UIKit

protocol HTableViewForPhotoCellDelegate: NSObjectProtocol {
  var reuseIdentifier: String {get set}
}

protocol HTableViewForPhotoDataSource: NSObjectProtocol{
  func numberOfColumnsForPhoto(hTableViewForPhoto: HTableViewForPhoto) -> Int
  func hTableViewForPhoto(hTableViewForPhoto: HTableViewForPhoto, cellForColumnAtIndex index: Int) -> ZoomImageScrollView
}

@objc protocol HTableViewForPhotoDelegate: NSObjectProtocol{
  optional func hTableViewForPhoto(hTableViewForPhoto: HTableViewForPhoto, widthForColumnAtIndex index: Int) -> CGFloat
  optional func hTableViewForPhoto(hTableViewForPhoto: HTableViewForPhoto, didSelectRowAtIndex: Int)
  optional func hTableViewForPhotoDidScroll(hTableViewForPhoto: HTableViewForPhoto)
  optional func hTableViewForPhotoWillBeginDragging(hTableViewForPhoto: HTableViewForPhoto)
  optional func hTableViewForPhotoDidEndDecelerating(hTableViewForPhoto: HTableViewForPhoto)
  optional func hTableViewForPhotoWillEndDragging(hTableViewForPhoto: HTableViewForPhoto)
  optional func hTableViewForPhotoDidEndDragging(hTableViewForPhoto: HTableViewForPhoto, willDecelerate decelerate: Bool)

}

extension UIScrollView{
  
//  scrollView的contentView的可见Rect
  func visibleRect() -> CGRect{
    
    var rect = CGRectZero
    rect.origin = self.contentOffset
    rect.size = self.bounds.size
    
    return rect
  }
}
class HTableViewForPhoto: UIScrollView {
  
  enum RollDirection{
    case Left
    case Right
  }
  
//  private var scrollView: UIScrollView!
  var dataSource: HTableViewForPhotoDataSource!{
    didSet{
      loadData()
    }
  }
  var delegateForHTableView: HTableViewForPhotoDelegate?
  
  //cell的个数
  private var numberOfColumns: Int!
  //可见cell的范围
  private var visibleRange = Range(start: 0, end: 0)
  //cell的高
  private var cellHeight: CGFloat = 0
  //所有cell的rect
  private var allRectList: [String] = []
  //可见的所有cell
  private var visibleCellList: [ZoomImageScrollView] = []
  //可供复用的cell
  private var reusableCellListDic = Dictionary<String, [ZoomImageScrollView]>()
  //储存上次一发生滑动的可见区域
  private var perviousVisibleRect: CGRect = CGRectZero
  //选中cell
  private var selectedIndex = -1
  private var isObserveContentSize = true
  
  override func layoutSubviews() {
//    loadData()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)

    let tap = UITapGestureRecognizer(target: self, action: "scrollViewDicTap:")
    tap.numberOfTapsRequired = 1
    tap.numberOfTouchesRequired = 1
    addGestureRecognizer(tap)
    
    showsHorizontalScrollIndicator = false
    cellHeight = CGRectGetHeight(frame)
    clipsToBounds = true
    
  }
  
  required init?
    (coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }
  
  private func loadData(){
    
    //delegate清空，否责会触发scrollview的滑动
    delegate = nil
    
    //contentoffset设为0
    contentOffset = CGPointZero
    //清空cell尺寸表
    allRectList = []
    //统统清空
    visibleRange.startIndex = 0
    visibleRange.endIndex = 0
    perviousVisibleRect = CGRectZero
    visibleCellList = []
    
    delegate = self
    numberOfColumns = dataSource.numberOfColumnsForPhoto(self)
    var cellWidth: CGFloat = 0
    //记录当前所有的cell所占宽度
    var currentAllWidth: CGFloat = 0
    
    //保存所有cell的rect 为 string
    for index in 0..<numberOfColumns {
      
      if delegateForHTableView != nil && delegateForHTableView!.respondsToSelector("hTableView:widthForColumnAtIndex:"){
        cellWidth = delegateForHTableView!.hTableViewForPhoto!(self, widthForColumnAtIndex: index)
      } else {
        //如果没实现hTableView:widthForColumnAtIndex: 那么宽度默认为scrollview的宽度
        cellWidth = CGRectGetWidth(frame)
      }
      let rect = CGRectMake(currentAllWidth, 0, cellWidth, cellHeight)
      allRectList += [String(NSStringFromCGRect(rect))]
      
      currentAllWidth += cellWidth
    }
    contentSize = CGSizeMake(currentAllWidth, cellHeight)
    
    loadCellWith(visibleRange.startIndex)
  }
  
  //获取可见cell的范围
  private func loadCellWith(startIndex: Int) {
    
    visibleRange.startIndex = startIndex
    var currentAllWidth: CGFloat = 0
    let visibleRect = self.visibleRect()
    var currentIndex = startIndex
    while currentAllWidth < CGRectGetWidth(visibleRect) && currentIndex < numberOfColumns{
      
      let rect = CGRectFromString(allRectList[currentIndex])
      var widthToAdd: CGFloat = 0
      
      if startIndex == currentIndex {
        widthToAdd = rect.maxX - visibleRect.minX
      } else {
        widthToAdd = CGRectGetWidth(rect)
      }
      
      addCellIntoHTableView(currentIndex, direction: .Left)
      currentAllWidth += widthToAdd
      currentIndex++
    }
    visibleRange.endIndex = currentIndex
    
  }
  
  /**
  向scrollView中添加cell
  
  :param: index     allRectList的index
  :param: direction 加入方向
  */
  private func addCellIntoHTableView(index: Int, direction: RollDirection){
    let cellRect = CGRectFromString(allRectList[index])
    let cell = dataSource.hTableViewForPhoto(self, cellForColumnAtIndex: index)
    cell.frame = cellRect
    addSubview(cell)
    
    switch direction{
    case .Left:
      visibleCellList += [cell]
    case .Right:
      visibleCellList.insert(cell, atIndex: 0)
    }
    
  }
  
  /**
  从scrollView中移除cell
  
  :param: index visibleCellList的index
  */
  private func removeFromHTableView(index: Int){
    let cellWillRemove = visibleCellList[index]
    let identifier = cellWillRemove.reuseIdentifier
    var reusableCellList = reusableCellListDic[identifier]
    if reusableCellList == nil{
      reusableCellList = []
    }
    reusableCellList! += [cellWillRemove]
    reusableCellListDic[identifier] = reusableCellList
    visibleCellList.removeAtIndex(index)
    cellWillRemove.removeFromSuperview()
  }
  
  //复用cell
  func dequeueReusableCellWithIdentifier(identifier: String) -> ZoomImageScrollView?{
    var reusableCellList = reusableCellListDic[identifier]
    if let _reusableCellList = reusableCellList {
      if _reusableCellList.count > 0 {
        let cell = reusableCellList?.removeAtIndex(0)
        reusableCellListDic[identifier] = reusableCellList
        return cell
      }
    }
    return nil
  }
  
  //单次滑动距离
  private func layoutCells(offset: CGFloat){
    
    let firstVisibleCellRect = visibleCellList[0].frame
    let lastVisibleCellRect = visibleCellList.last!.frame
    
    //左滑
    if offset > 0 {
      
      //左滑时，最左边一个滑出scrollView，则移除，加入复用列表准备复用
      if CGRectGetMaxX(firstVisibleCellRect) <= CGRectGetMinX(self.visibleRect()){
        removeFromHTableView(0)
        visibleRange.startIndex++
      }
      
      //左滑时，最右边一个完全移进scrollView时，加载一个cell
      if CGRectGetMaxX(lastVisibleCellRect) <= CGRectGetMaxX(self.visibleRect()){
        if visibleRange.endIndex < numberOfColumns {
          addCellIntoHTableView(visibleRange.endIndex++, direction: .Left)
        }
      }
    } else {
      //右滑同左滑
      if CGRectGetMinX(lastVisibleCellRect) >= CGRectGetMaxX(self.visibleRect()){
        removeFromHTableView(visibleCellList.count - 1)
        visibleRange.endIndex--
      }
      
      if CGRectGetMinX(firstVisibleCellRect) >= CGRectGetMinX(self.visibleRect()){
        if visibleRange.startIndex > 0 {
          addCellIntoHTableView(--visibleRange.startIndex, direction: .Right)
        }
      }
    }
    
  }
  
  //根据偏移量大小拆分，防止一次移动的距离大于两个cell的距离时，会少添加cell
  private func layoutCellsWithContentOffset(offset: CGFloat){
    var offsetToMove: CGFloat = 0
    //取偏移量的绝对值，方便计算
    var originOffset = abs(offset)
    while originOffset > 0 {
      
      var removeWidth: CGFloat = 0
      var showWidth: CGFloat = 0
      
      //向左滑时
      if offset > 0{
        if visibleRange.endIndex > numberOfColumns {
          break
        }
        //左边第一个即将滑出tableview的距离
        removeWidth = CGRectGetMaxX(CGRectFromString(allRectList[visibleRange.startIndex])) - CGRectGetMinX(perviousVisibleRect)
        //下一个即将加入的cell的宽度
        if visibleRange.endIndex == allRectList.count {
          //当左滑到头时，下一个cell不存在，则去一个尽可能大的值来使下一次layoutcell以左边移除的cell的宽度为准
          showWidth = CGFloat(MAXFLOAT)
        } else {
          showWidth = CGRectGetWidth(CGRectFromString(allRectList[visibleRange.endIndex]))
        }
      } else {
        //向右滑时
        if visibleRange.startIndex < 0 {
          break
        }
        //右边第一个即将滑出tableview的距离
        removeWidth = CGRectGetMaxX(perviousVisibleRect) - CGRectGetMinX(CGRectFromString(allRectList[visibleRange.last!]))
        //下一个即将加入的cell的宽度
        if visibleRange.startIndex == 0 {
          //同左滑
          showWidth = CGFloat(MAXFLOAT)
        } else {
          showWidth = CGRectGetWidth(CGRectFromString(allRectList[visibleRange.startIndex - 1]))
        }
      }
      
      //取两者中较小的一个作为这一次的偏移量
      offsetToMove = min(removeWidth, showWidth)
      
      //当removeWidth为0时，取showWidth
      if removeWidth == 0 {
        offsetToMove = showWidth
      }
      
      //这里有个bug，cell的width设为1时，会自动扩大，不知道为什么
      if offsetToMove <= 0 {
        break
      }
      
      //当当前剩余的偏移量小于算出的偏移量时，只偏移当前剩余的偏移量
      if originOffset - offsetToMove < 0 {
        offsetToMove = originOffset
      }
      //计算剩余偏移量
      originOffset -= offsetToMove
      
      //根据之前偏移量的方向设置当前偏移量的方向
      offsetToMove = offset < 0 ? -offsetToMove : offsetToMove
      layoutCells(offsetToMove)
      
    }
  }
  
  /**
   通过当前位置获得当前显示的一个cell的index
   
   - returns: index
   */
  func getStartIndex() -> Int {
    
    for (index, rectString) in allRectList.enumerate() {
      
      let rect = CGRectFromString(rectString)
      if rect.minX <= visibleRect().minX && rect.maxX >= visibleRect().minX {
        return index
      }
      
    }
    return 0
  }
  
  //scrollView的点击事件
  func scrollViewDicTap(tap: UITapGestureRecognizer){
    //触摸点
    let tapPoiont = tap.locationInView(self)
    //遍历可见cell，查找被点击的cell
    for cell in visibleCellList  {
      if CGRectGetMinX(cell.frame) < tapPoiont.x && CGRectGetMaxX(cell.frame) >= tapPoiont.x {
        didSelectedCell(cell)
      }
    }
  }
  
  func didSelectedCell(cell: ZoomImageScrollView){
    let currentSelectedIndex = cell.tag
    delegateForHTableView?.hTableViewForPhoto?(self, didSelectRowAtIndex: currentSelectedIndex)
    selectedIndex = currentSelectedIndex
  }
  
  func getAllItemsRect() -> [CGRect] {
    return allRectList.map({CGRectFromString($0)})
  }
  
  func itemForRowAtIndex(index: Int) -> ZoomImageScrollView {
    
    let item = dataSource.hTableViewForPhoto(self, cellForColumnAtIndex: index)
    item.frame = CGRectFromString(allRectList[index])
    
    return item
  }
  
  func indexForRowAtPoint(point: CGPoint) -> Int?{
    
    for (index, rectString) in allRectList.enumerate() {
      let frame = CGRectFromString(rectString)
      
      if frame.minX <= point.x && frame.maxX >= point.x {
        return index
      }
    }
    
    return nil
  }
  
  func cellForRowAtIndex(index: Int) -> ZoomImageScrollView {
    
    if visibleRange.contains(index) && !visibleRange.isEmpty{
      
      let indexOfVisibleCells = index - visibleRange.first!
      return visibleCellList[indexOfVisibleCells]
    }
    
    let cell = dataSource.hTableViewForPhoto(self, cellForColumnAtIndex: index)
    cell.frame = CGRectFromString(allRectList[index])
    
    return cell
  }
  
  /******************************************************************************
  *  Public Method
  ******************************************************************************/
  //MARK: - Public Method
  
  //重新加载数据
  func reload(){
    loadData()
  }
  
  /**
  当启用了pagingEnabled时,使用此方法直接滑至指定页数
  
  :param: index    滑动到的页数
  :param: animated 是否播放动画，默认false
  */
  func moveToPage(index: Int, animated: Bool = false){
    
    isObserveContentSize = false
    
    let offset = CGFloat(index) * CGRectGetWidth(frame)
    setContentOffset(CGPoint(x: offset, y: 0) , animated: animated)

  }
  
}

extension HTableViewForPhoto: UIScrollViewDelegate {
  
  //scrollView的回调
  func scrollViewDidScroll(scrollView: UIScrollView) {

    delegateForHTableView?.hTableViewForPhotoDidScroll?(self)
    let visibleRect = self.visibleRect()
    let offset = CGRectGetMinX(visibleRect) - CGRectGetMinX(perviousVisibleRect)
    
    //当一次移动的距离超过本身的可视宽度的2倍时则重新添加cell
    if offset > CGRectGetWidth(frame) * 2 {
      
      perviousVisibleRect = visibleRect
      
      for cell in visibleCellList {
        cell.removeFromSuperview()
      }
      
      visibleCellList.removeAll()
      
      let startIndex = getStartIndex()
      loadCellWith(startIndex)
            
      return
    }
    
    layoutCellsWithContentOffset(offset)
    perviousVisibleRect = visibleRect
    
  }
  
  func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    delegateForHTableView?.hTableViewForPhotoWillBeginDragging?(self)
  }

  func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {    
    delegateForHTableView?.hTableViewForPhotoWillEndDragging?(self)
  }
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    delegateForHTableView?.hTableViewForPhotoDidEndDecelerating?(self)
  }
  
  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    delegateForHTableView?.hTableViewForPhotoDidEndDragging?(self, willDecelerate: decelerate)
  }
}

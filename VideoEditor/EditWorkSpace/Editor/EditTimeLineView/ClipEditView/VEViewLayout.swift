//
//  CustomViewLayout 2.swift
//  SwiftUIView
//
//  Created by NancyYang on 2024-09-24.
//
import UIKit
import SwiftUI
import OSLog

@MainActor public protocol VELayoutDelegate : UICollectionViewDelegate {

    func ve_collectionView(sizeForItemAt indexPath: IndexPath) -> CGSize
    func ve_collectionViewDidPrepared(itemAttributes: [IndexPath: UICollectionViewLayoutAttributes])
    func ve_editingInfo() -> EditingInfo?
    
}

class VEViewLayout : UICollectionViewLayout {
    weak open var delegate: (any VELayoutDelegate)?
           
    open var minimumLineSpacing: CGFloat = 0
    open var minimumInteritemSpacing: CGFloat = 0
    open var itemSize: CGSize = CGSizeZero
    let gap: CGFloat = 2
    
    init(delegate: (any VELayoutDelegate)?) {
        super.init()
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var previousAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    var currentAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    var contentSize = CGSizeZero
    var selectdCellIndexPath : IndexPath?
    
    var dragTouchPosition: CGPoint?
    var dragItemIndexPath: NSIndexPath?
    
    override func prepare() {
        super.prepare()
        
        if let collectionView = collectionView, let delegate = delegate {
            if let editingInfo = delegate.ve_editingInfo(), editingInfo.isDragging() {
                self.prepareDragging(collectionView: collectionView, editingInfo: editingInfo, delegate: delegate)
            } else {
                self.prepareNormal(collectionView: collectionView, delegate: delegate)
            }
            
            Logger.viewCycle.debug("yxy prepareDragging called")
            delegate.ve_collectionViewDidPrepared(itemAttributes: currentAttributes)
        }
    }
    func prepareNormal(collectionView:UICollectionView, delegate: VELayoutDelegate) {
        
        previousAttributes = currentAttributes
        contentSize = CGSizeZero
        currentAttributes = [:]
        
        var y: CGFloat = 0
        let rowHeight: CGFloat = 50
        var maxX : CGFloat = 0
        
        for section in 0..<collectionView.numberOfSections {
            let row = collectionView.numberOfItems(inSection: section)
            var x: CGFloat = 0
            
            for itemIndex in 0..<row {
                let indexPath = IndexPath(row: itemIndex, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                
                let size = delegate.ve_collectionView(sizeForItemAt: indexPath)
                attributes.frame = CGRectMake(x, y, size.width, size.height)
                
                currentAttributes[indexPath] = attributes
                x += (size.width + gap)
            }
            
            maxX = max(maxX, x)
            y += (rowHeight + gap)
        }
        contentSize = CGSizeMake(maxX, y)
        Logger.viewCycle.debug("yxy prepareNormal called")
    }
    func prepareDragging(collectionView: UICollectionView, editingInfo:EditingInfo, delegate: VELayoutDelegate) {
        //TODO: audio and video different
        let posY = editingInfo.initialFrame.origin.y
        let editingRow = editingInfo.editingIndexPath.row
        let editingSection = editingInfo.editingIndexPath.section
        
        if editingInfo.dragDirection == .left {
            let fixedX = editingInfo.initialFrame.origin.x + editingInfo.initialFrame.width
            var posX = fixedX
        
            for i in stride(from: editingRow, through: 0, by: -1) {
                let crtIndexPath = IndexPath(row: i, section: editingSection)
                let size = delegate.ve_collectionView(sizeForItemAt: crtIndexPath)
                posX = posX - size.width
                let frame = CGRect(origin: CGPoint(x: posX, y: posY), size: size)
                //Logger.viewCycle.debug("yxy index=\(crtIndexPath) frame = \(frame)")
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: crtIndexPath)
                attributes.frame = frame
                currentAttributes[crtIndexPath] = attributes
                
                posX = posX-gap
            }
            
        } else if editingInfo.dragDirection == .right {
            let maxRow = collectionView.numberOfItems(inSection: editingSection)
            let fixedX = editingInfo.initialFrame.origin.x
            var posX = fixedX
        
            for i in stride(from: editingRow, to: maxRow, by: 1) {
                let crtIndexPath = IndexPath(row: i, section: editingSection)
                let size = delegate.ve_collectionView(sizeForItemAt: crtIndexPath)
                let frame = CGRect(origin: CGPoint(x: posX, y: posY), size: size)
                //Logger.viewCycle.debug("yxy index=\(crtIndexPath) frame = \(frame)")
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: crtIndexPath)
                attributes.frame = frame
                currentAttributes[crtIndexPath] = attributes
                
                posX = posX + size.width + gap
            }
        } else {
            //Logger.viewCycle.debug("yxy prepareDragging error")
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return contentSize
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return currentAttributes[indexPath]
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let f = currentAttributes.filter { CGRectIntersectsRect(rect, $0.value.frame)}
        return Array(f.values)
    }
    
    
    
    // MARK: - invalidate
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let oldBounds = collectionView?.bounds, !CGSizeEqualToSize(oldBounds.size, newBounds.size) {
            return true
        }
        return false
    }
    // MARK: - Layout attributes
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        Logger.viewCycle.debug("query appear item \(itemIndexPath)")
        return previousAttributes[itemIndexPath]
    }
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        Logger.viewCycle.debug("query disappear item \(itemIndexPath)")
        return layoutAttributesForItem(at: itemIndexPath)
    }
    
    
    
//    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
//        guard let selectedCellIndexPathes = collectionView?.indexPathsForSelectedItems, selectedCellIndexPathes.count == 1 else {
//            return proposedContentOffset
//        }
//        
//        let selectIndexPath = selectedCellIndexPathes[0]
//        var finalContentOffset = proposedContentOffset
//        
//        if let frame = layoutAttributesForItem(at: selectIndexPath)?.frame {
//            let collectionViewWidth = collectionView?.bounds.size.width ?? 0
//            
//            let collectionViewLeft = proposedContentOffset.x
//            let collectionViewRight = collectionViewLeft + collectionViewWidth
//            
//            let cellLeft = frame.origin.x
//            let cellRight = cellLeft + frame.size.width
//            
//            if cellLeft < collectionViewLeft {
//                finalContentOffset = CGPointMake(cellLeft, 0.0)
//            } else if cellRight > collectionViewRight {
//                finalContentOffset = CGPointMake(collectionViewLeft + (cellRight - collectionViewRight), 0.0)
//            }
//        }
//        
//        return finalContentOffset
//    }
}

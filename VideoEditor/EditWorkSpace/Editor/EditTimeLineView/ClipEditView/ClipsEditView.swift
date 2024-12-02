//
//  ClipsEditView.swift
//  SwiftUIView
//
//  Created by NancyYang on 2024-09-23.
//

import UIKit
import AVFoundation
import SwiftUI

struct ClipsEditView:UIViewControllerRepresentable {
    @Binding var editingSession: EditSession
    let vc:ClipsEditViewController
    init(editSession: Binding<EditSession>) {
        _editingSession = editSession
        self.vc  = ClipsEditViewController(editSession: editSession)
    }
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ClipsEditViewController(editSession: $editingSession)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}


class ClipsEditViewController: UIViewController,
                               VELayoutDelegate,
                               UICollectionViewDataSource,
                               UICollectionViewDelegate,
                               UICollectionViewDragDelegate,
                               UICollectionViewDropDelegate,
                               UIScrollViewDelegate,
                               ClipDragViewDelegate {
    var collectionView: UICollectionView!
    var dragView:ClipDragView!
    var needUpdateDragView = false
    var editVM = ClipEditVM(videoClips: [])
    private var draggingVertically : Bool = true
    private var initialContentOffset = CGPoint.zero
    
    @Binding var editSession: EditSession
    init (editSession: Binding<EditSession>) {
        self._editSession = editSession
        super .init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

                       
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        for photo in editSession.photos {
            let duration =  CMTime(seconds: 2, preferredTimescale: kDefaultTimeScale)
            let clip = ClipData(duration: duration, type: .video)
            for i in 0..<2 {
                clip.thumbnails.append(photo.image)
            }
            editVM.videoClips.append(clip)
        }
        
        for audio in editSession.audios {
            let duration =  CMTime(seconds: 2, preferredTimescale: kDefaultTimeScale)
            let clip = ClipData(duration: duration, type: .audio)
            editVM.audioClips?.append(clip)
        }

        
        // Setup the layout
        let layout = VEViewLayout(delegate: self)
        layout.delegate = self
        // Initialize the collection view
        let rect = view.bounds;
        collectionView = UICollectionView(frame: rect, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isDirectionalLockEnabled = true
        collectionView.dragInteractionEnabled = false
        
        // Add long-press gesture recognizer for interactive movement
        //let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        //collectionView.addGestureRecognizer(longPressGesture)
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        self.dragView = ClipDragView(frame: CGRectZero)
        self.dragView.delegate = self
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if collectionView.contentInset.left == 0 {
            let halfWidth = collectionView.bounds.width / 2
            collectionView.contentInset = UIEdgeInsets(top: 0, left: halfWidth, bottom: 0, right: halfWidth)
            // Optionally, you can also adjust the scrollIndicatorInsets if needed
            //collectionView.scrollIndicatorInsets = collectionView.contentInset
            
            initialContentOffset =  CGPointMake(-halfWidth, 0)
            collectionView.contentOffset = initialContentOffset
        }
    }
    // MARK: - ClipDragViewDelegate
    func viewDragBegan(_ dragView: UIView, isLeft: Bool) {
        guard editVM.isEditing() else {
            return
        }
        if let editingInfo = editVM.editingInfo,
           let cell = collectionView.cellForItem(at: editingInfo.editingIndexPath) {
            editingInfo.dragDirection = isLeft ? .left : .right
            editingInfo.initialFrame = cell.frame
            
            //setting the max
            if let clip = editVM.clip(at:editingInfo.editingIndexPath) {
                let ratio = kThumbnailSize.width / kSecsPerThumbnail.seconds
                let maxCellWidth  = (isLeft ? clip.endTime.seconds : (clip.duration - clip.startTime).seconds) * ratio
                self.dragView.maxClipWidth = maxCellWidth
            }
        }

    }
    func viewDidDrag(_ dragView: UIView, widthDiff: Double, isLeft: Bool) {
        if let editingInfo = editVM.editingInfo {
            editingInfo.editingWidthDiff = widthDiff
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    func viewDragEnded(_ dragView: UIView, widthDiff: Double, isLeft: Bool) {
        //adjust duration
        if let editingInfo = editVM.editingInfo, let editClip = editVM.clip(at: editingInfo.editingIndexPath) {
            let diffSec = widthDiff * (kSecsPerThumbnail.seconds / kThumbnailSize.width)
            let diffTime = CMTime(seconds: diffSec, preferredTimescale: kDefaultTimeScale)
            if isLeft {
                editClip.startTime = editClip.startTime - diffTime
            } else {
                editClip.endTime = editClip.endTime + diffTime
            }
            editingInfo.dragDirection = .none
            
            print("yxy viewDragEnded")
            self.needUpdateDragView = true
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    func viewDidRemovedFromSuperview(_ dragView: UIView) {
        editVM.cancelEditing()
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("yxy didSelectItemAt")
        if let cell = collectionView.cellForItem(at:indexPath) {
            if editVM.isEditing() {
                self.dragView.removeFromSuperview()
                editVM.cancelEditing()
            } else {
                let editInfo = EditingInfo(editingIndexPath: indexPath)
                editInfo.initialFrame = cell.frame
                editVM.activeEditing(editInfo: editInfo)

                let dragViewRect = ClipDragView.viewFrame(clipFrame: cell.frame)
                self.dragView.frame = dragViewRect
                collectionView.addSubview(self.dragView)
            }
        }
    }
                                   
    
    // MARK: - VELayoutDelegate
    func ve_collectionView(sizeForItemAt indexPath: IndexPath) -> CGSize {
        let clip = editVM.videoClips[indexPath.row]

        var size = CGSizeZero
        let height = clip.type == .video ? kThumbnailSize.height : 20
        var width:CGFloat = 0
        //drag timing
        if let editingInfo = editVM.editingInfo, editVM.isEditing(indexPath: indexPath) && self.dragView.isDraging {
            width = editingInfo.initialFrame.width + self.dragView.widthDifference
            size = CGSizeMake(width, CGFloat(height))
            return size
        }
        //scale timing

        
        //normal timing
        let clipSeconds = (clip.endTime - clip.startTime).seconds
        width = (Double(kThumbnailSize.width) / kSecsPerThumbnail.seconds)  * clipSeconds
        size = CGSizeMake(width, CGFloat(height))
        return size
    }
    func ve_editingInfo() -> EditingInfo? {
        return editVM.editingInfo
    }

    func ve_collectionViewDidPrepared(itemAttributes: [IndexPath : UICollectionViewLayoutAttributes]) {
        if self.needUpdateDragView {
            if let editingInfo = editVM.editingInfo, let attr = itemAttributes[editingInfo.editingIndexPath] {
                let dragViewRect = ClipDragView.viewFrame(clipFrame: attr.frame)
                self.dragView.frame = dragViewRect
                collectionView.addSubview(self.dragView)
            }
        }
    }
                                   
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = editVM.numberOfItemsInSection(section: section)
        return count
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let secCnt =  editVM.videoClips.count
        return secCnt
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .blue
        
        //let clip = editVM.clips[indexPath.section][indexPath.row]
        let pos = "\(indexPath.section) - \(indexPath.row)"
        
        if let label = cell.contentView.viewWithTag(100) as? UILabel {
            label.text = pos
        } else {
            // Add label to cell
            let label0 = UILabel(frame: cell.contentView.bounds)
            label0.tag = 100
//            label0.textAlignment = .center
            label0.textColor = .white
            label0.text = pos
            cell.contentView.addSubview(label0)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Reorder the data in the data source array
//        let movedItem = items.remove(at: sourceIndexPath.item)
//        items.insert(movedItem, at: destinationIndexPath.item)
        print("move item from \(sourceIndexPath) to \(destinationIndexPath)")
    }
    
    // Enable reordering in the collection view
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - UICollectionViewDragDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        UIView.animate(withDuration: 0.3) {
//            collectionView.performBatchUpdates(nil, completion: nil)
            collectionView.collectionViewLayout.invalidateLayout()
//            collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        }
        
        let item = editVM.videoClips[indexPath.row]
        let itemProvider = NSItemProvider(object: item.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return []
    }
    /* Called to request items to add to an existing drag session in response to the add item gesture.
     * You can use the provided point (in the collection view's coordinate space) to do additional hit testing if desired.
     * If not implemented, or if an empty array is returned, no items will be added to the drag and the gesture
     * will be handled normally.
     */
//    - (NSArray<UIDragItem *> *)collectionView:(UICollectionView *)collectionView itemsForAddingToDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
//
//    }

    /* Allows customization of the preview used for the item being lifted from or cancelling back to the collection view.
     * If not implemented or if nil is returned, the entire cell will be used for the preview.
     */
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        print("yxy dragPreviewParametersForItemAt")
        let previewParameters = UIDragPreviewParameters()
        
        // Customizing the visible part of the drag preview
        let cell = collectionView.cellForItem(at: indexPath)
        var rect = cell!.bounds
        rect.origin = CGPoint(x: 0, y: 0)
        rect.size = CGSize(width: 50, height: 50)
        print("yxy rect = \(rect)")
        let visiblePath = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        
        previewParameters.visiblePath = visiblePath // Only show the rounded rectangle part of the cell
        previewParameters.backgroundColor = .clear // Optional: make background clear for transparency
        
        let cellFrame = cell!.frame
        let diff = cellFrame.origin.x - 50.0 * CGFloat(indexPath.row)
        let crtOffset = collectionView.contentOffset
        collectionView.contentOffset = CGPoint(x: crtOffset.x - diff, y: 0)
        print("yxy diff = \(diff)")
        
        
        return previewParameters
    }


    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: any UIDragSession) {
        print("yxy dragSessionWillBegin")
        
    }
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: any UIDragSession) {
        print("yxy dragSessionDidEnd")
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - UICollectionViewDropDelegate
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        print("yxy performDropWith index = \(destinationIndexPath.row)")
        coordinator.items.forEach { dropItem in
            if let sourceIndexPath = dropItem.sourceIndexPath {
                collectionView.performBatchUpdates({
                    let movedItem = editVM.videoClips.remove(at: sourceIndexPath.item)
                    editVM.videoClips.insert(movedItem, at: destinationIndexPath.item)
                    collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
                }, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        print("yxy canHandle")
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: any UIDropSession) {
        print("yxy dropSessionDidExit")
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
//        if let indexPath = destinationIndexPath {
//            print("yxy withDestinationIndexPath  = \(indexPath.row)")
//            print("yxy" + Date().description)
//        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        initialContentOffset = scrollView.contentOffset
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.superview)
        draggingVertically = abs(velocity.x) < abs(velocity.y)
        
        print("drag is vertical \(draggingVertically)")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //let offset = scrollView.contentOffset
//        if (draggingVertically == true){
//            offset.x = initialContentOffset.x
//        } else {
//            offset.y = initialContentOffset.y
//        }
//        scrollView.contentOffset = offset
        
        //print("scrollViewDidScroll  \(offset)")
    }
    
    // MARK: - Long Press Gesture Handling
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
            
        case .ended:
            collectionView.endInteractiveMovement()
            
        default:
            collectionView.cancelInteractiveMovement()
        }
    }

}

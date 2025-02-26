//
//  ClipDragView.swift
//  SwiftUIView
//
//  Created by NancyYang on 2024-09-13.
//

import UIKit
import OSLog
let kMinItemWidth:CGFloat = 5.0

@MainActor public protocol ClipDragViewDelegate: NSObjectProtocol {
    func viewDragBegan(_ dragView: UIView, isLeft: Bool)
    func viewDidDrag(_ dragView: UIView, widthDiff: Double, isLeft: Bool)
    func viewDragEnded(_ dragView: UIView, widthDiff: Double, isLeft: Bool)
    func viewDidRemovedFromSuperview(_ dragView: UIView)
}

class ClipDragView: UIView {
    static let handleWidth: CGFloat = 20.0
    static let hightExpand: CGFloat = 3.0
    
    var leftHandleView:UIView!
    var rightHandleView:UIView!
    var initialSize: CGSize = CGSizeZero
    var initialOrigin: CGPoint = CGPointZero
    weak open var delegate: (any ClipDragViewDelegate)?
    var maxClipWidth:CGFloat = CGFLOAT_MAX
    var isDraging = false
    var isDragLeft = false
    var widthDifference:CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 1.0
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        
        addHandleViews(frame: frame)
        
       
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
        
        let rightPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRightPan(_:)))
        self.rightHandleView.addGestureRecognizer(rightPanGesture)
        //self.addGestureRecognizer(panGesture)
        
        let leftPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleLeftPan(_:)))
        self.leftHandleView.addGestureRecognizer(leftPanGesture)
    }
    
    func addHandleViews(frame: CGRect) {
        let handleFrame = CGRect(x:frame.size.width-ClipDragView.handleWidth, y: 0, width: ClipDragView.handleWidth, height: frame.height)
        self.rightHandleView = UIView(frame: handleFrame)
        self.rightHandleView.backgroundColor = UIColor.red
        self.addSubview(self.rightHandleView)
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightHandleView.topAnchor.constraint(equalTo: self.topAnchor),
            rightHandleView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rightHandleView.widthAnchor.constraint(equalToConstant: ClipDragView.handleWidth),
            rightHandleView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        self.leftHandleView = UIView(frame: CGRect(origin: CGPointZero, size: handleFrame.size))
        self.leftHandleView.backgroundColor = UIColor.red
        self.addSubview(self.leftHandleView)
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftHandleView.topAnchor.constraint(equalTo: self.topAnchor),
            leftHandleView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            leftHandleView.widthAnchor.constraint(equalToConstant: ClipDragView.handleWidth),
            leftHandleView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        ])
    }
    
    //MARK: GestureRecognizer
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        self.removeFromSuperview()
        self.delegate?.viewDidRemovedFromSuperview(self)
    }
    @objc func handleLeftPan(_ gesture: UIPanGestureRecognizer) {
        handlePanGesture(gesture, isLeft: true)
    }
    @objc func handleRightPan(_ gesture: UIPanGestureRecognizer) {
        handlePanGesture(gesture, isLeft: false)
    }
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, isLeft: Bool){
        switch gesture.state {
        case .began:
            widthDifference = 0
            // Save the initial touch point and view size
            initialSize = self.frame.size
            initialOrigin = self.frame.origin
            Logger.viewCycle.debug("yxy \(isLeft ? "left" : "right") began")
            self.delegate?.viewDragBegan(self, isLeft: isLeft)
        case .changed:
            self.isDraging = true
            self.isDragLeft = isLeft
            // Calculate the new size based on the gesture movement
            
            let translation = gesture.translation(in: self.superview)
            let widthChange = translation.x
            
            
            let minWidth = self.minViewWidth()
            let maxWidth = self.maxViewWidth()
            
            var newWidth:CGFloat = 0
            var origin = self.initialOrigin
            if isLeft {
                newWidth = min(maxWidth, max(initialSize.width - widthChange, minWidth))
                origin.x = origin.x - (newWidth - initialSize.width)
            } else {
                newWidth = min(maxWidth, max(initialSize.width + widthChange, minWidth))
            }
            self.frame = CGRect(origin: origin, size: CGSize(width: newWidth, height: self.frame.height))
            
            self.widthDifference = newWidth - initialSize.width
            self.delegate?.viewDidDrag(self, widthDiff: self.widthDifference, isLeft: isLeft)
            
            var text = "yxy changed"
            text += (" moved X  = " + String(format: "%.2f", translation.x))
            text += (" newWidth = " + String(format: "%.2f", newWidth))
            text += (" realDiff = " + String(format: "%.2f", self.widthDifference))
            print(text)
        case .ended:
            self.isDraging = false
            self.isDragLeft = false
            self.widthDifference = self.frame.width - initialSize.width
            Logger.viewCycle.debug("yxy ended widthDiff \(String(format: "%.2f", self.widthDifference))")

            self.delegate?.viewDragEnded(self, widthDiff: self.widthDifference, isLeft: isLeft)
        default:
            break
        }
    }
    
    func maxViewWidth() -> CGFloat {
        return ClipDragView.handleWidth * 2 + maxClipWidth
    }
    func minViewWidth() -> CGFloat {
        return ClipDragView.handleWidth * 2 + kMinItemWidth
    }
    
    static func viewSize(clipViewSize: CGSize) -> CGSize {
        return CGSize(width: clipViewSize.width + ClipDragView.handleWidth*2, height: clipViewSize.height + ClipDragView.hightExpand)
    }
    static func viewFrame(clipFrame: CGRect) -> CGRect {
        let origin = CGPoint(x: clipFrame.origin.x - ClipDragView.handleWidth, y: clipFrame.origin.y - (ClipDragView.hightExpand/2.0))
        return CGRect(origin:origin , size: ClipDragView.viewSize(clipViewSize: clipFrame.size))
    }
    
    //MARK: system
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

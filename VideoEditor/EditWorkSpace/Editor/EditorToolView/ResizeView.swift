//
//  ResizeView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-09-04.
//

import SwiftUI
import UIKit

@MainActor public protocol ResizeViewDelegate: NSObjectProtocol {
    func viewDidDrag(_ dragView: UIView, dragOffset: Double)
}

class ResizeView: UIView {
    static let handleWidth: CGFloat = 30.0
    static let hightExpand: CGFloat = 4.0
    
    var rightHandleView:UIView!
    var initialSize: CGSize = CGSizeZero // Initial size of the Resize view
    var initialTouchPoint: CGPoint = .zero // Store the initial touch point when the gesture begins
    weak open var delegate: (any ResizeViewDelegate)?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 1.0
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        
        let handleFrame = CGRect(x:frame.size.width-ResizeView.handleWidth, y: 0, width: ResizeView.handleWidth, height: frame.height)
        self.rightHandleView = UIView(frame: handleFrame)
        self.rightHandleView.backgroundColor = UIColor.red
        self.addSubview(self.rightHandleView)
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightHandleView.topAnchor.constraint(equalTo: self.topAnchor),
            rightHandleView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rightHandleView.widthAnchor.constraint(equalToConstant: ResizeView.handleWidth),
            rightHandleView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
       
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.rightHandleView.addGestureRecognizer(panGesture)
        //self.addGestureRecognizer(panGesture)
    }
    
    //MARK: UIPanGestureRecognizer
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            // Save the initial touch point and view size
            initialTouchPoint = gesture.location(in: self)
            initialSize = self.frame.size
        case .changed:
            // Calculate the new size based on the gesture movement
            let currentTouchPoint = gesture.location(in: self)
            let widthChange = currentTouchPoint.x - initialTouchPoint.x
            print("yxy widthChange = \(widthChange)")
            
            
            let newWidth = max(initialSize.width + widthChange, ResizeView.handleWidth * 2)
            self.frame = CGRect(origin: self.frame.origin, size: CGSize(width: newWidth, height: self.frame.height))
            self.delegate?.viewDidDrag(self, dragOffset: newWidth)

        default:
            break
        }
    }
    
    
    static func viewSize(clipViewSize: CGSize) -> CGSize {
        return CGSize(width: clipViewSize.width + ResizeView.handleWidth, height: clipViewSize.height + ResizeView.hightExpand)
    }
    static func viewFrame(clipFrame: CGRect) -> CGRect {
        let origin = CGPoint(x: clipFrame.origin.x, y: -(ResizeView.hightExpand/2.0))
        return CGRect(origin:origin , size: ResizeView.viewSize(clipViewSize: clipFrame.size))
    }
    
    //MARK: system
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


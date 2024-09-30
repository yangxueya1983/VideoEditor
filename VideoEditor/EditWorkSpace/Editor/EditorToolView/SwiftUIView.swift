//
//  SwiftUIView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-09-04.
//

import SwiftUI
let kSize = CGSize(width: 50, height: 50)
struct SwiftUIView: View {
    @State private var items = ["1", "2", "3", "4", "5", "6"]
    
    var body: some View {
        ClipUI() {
            Color.gray
            HStack(spacing: 20) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .frame(width: kSize.width, height: kSize.height)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
            
        }
        .background(.red)
        .frame(width: 200, height: kSize.height)
        
    }
}


struct ClipUI<Content: View>: View {
    var content: () -> Content
    
    @State private var initialWidth:Double = 150
    @State private var initialDragPosition: Double = 0
    @State private var dragOffset: Double = 0
    @State private var isDragging = false
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        //ZStack(alignment: .topLeading, content: {
            content()
            .overlay(
                Rectangle()
                    .fill(Color.red.opacity(0.5))
                    .frame(width: 20)
                    .offset(x: (initialWidth + dragOffset) / 2 + 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    
                                    initialDragPosition = value.startLocation.x
                                }
                                // Update the drag offset as the user drags
                                dragOffset = value.translation.width
                                //width = originWidth + dragOffset
                                // Limit minimum width
                                //width = max(50, width)
                            }
                            .onEnded({ value in
                                isDragging = false
                                
                                initialWidth = initialWidth + dragOffset
                                dragOffset = 0
                            })
                    )
            )
        //})
        
    }
}


#Preview {
    SwiftUIView()
}

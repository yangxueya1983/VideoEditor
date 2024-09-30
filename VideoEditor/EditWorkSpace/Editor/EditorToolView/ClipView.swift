//
//  ClipView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-09-04.
//

import SwiftUI

let kThumbImgSize = CGSize(width: 50, height: 50)
let kTransitionBtnSize = CGSize(width: 20, height: 20)
let kSecondsPerPic = 1.0

struct ClipView: View {
    let path:URL?
    let hasTransitionBtn:Bool
    @Binding var showTransitionMenu:Bool
    @State var transType = TransitionType.None
    @State var thumbImages:[UIImage] = []
    @State var editable = false
    @State var clipWidth = kThumbImgSize.width * 3
    
    init(path: URL,
         hasTransitionBtn: Bool,
         showTransitionMenu: Binding<Bool>,
         transType: TransitionType = TransitionType.None) {
        self.path = path
        self.hasTransitionBtn = hasTransitionBtn
        self._showTransitionMenu = showTransitionMenu
        self._transType = State(initialValue: transType)
    }
    
    init(image: UIImage,
         hasTransitionBtn: Bool,
         showTransitionMenu: Binding<Bool>,
         transType: TransitionType = TransitionType.None) {
        self.path = nil
        self.hasTransitionBtn = hasTransitionBtn
        self._showTransitionMenu = showTransitionMenu
        self._transType = State(initialValue: transType)
        self._thumbImages = State(initialValue: [image, image, image])
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0, content: {
                ForEach(thumbImages, id: \.self) { item in
                    Image(uiImage:item)
                        .resizable()
                        .scaledToFill()
                        .frame(width: kThumbImgSize.width, height: kThumbImgSize.height)
                        .clipped()
                    
                }
            })
            .frame(width: clipWidth)
            
            if hasTransitionBtn {
                Button {
                    showTransitionMenu = true
                } label: {
                    Image(systemName: transType == .None ? "checkmark.square" : "checkmark.square.fill")
                }
                .frame(width: kTransitionBtnSize.width, height: kTransitionBtnSize.height)
                .offset(x: -kTransitionBtnSize.width/2.0)
            }
            
            if editable {
                
            }
        }
        .task {
            if thumbImages.count == 0 {
                if let path {
                    thumbImages = getThumbImages(filePath: path)
                }
            }
        }
    }
    
    func getThumbImages(filePath:URL) -> [UIImage] {
        var imgArr:[UIImage] = []
        let img = UIImage(contentsOfFile: filePath.path())
        for _ in 0..<3 {
            if let img {
                imgArr.append(img)
            }
        }
        return imgArr
    }
    

}

#Preview {
    @State var showTransitionMenu = false
    let image = UIImage(named:"avatar")!
    return ClipView(image: image,
             hasTransitionBtn: false,
             showTransitionMenu: $showTransitionMenu)
}

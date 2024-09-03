//
//  EditorToolView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-08-20.
//

import SwiftUI
let kThumbImgSize = CGSize(width: 50, height: 50)
let kTransitionBtnSize = CGSize(width: 20, height: 20)

struct EditorToolView: View {
    @Binding var imageArray:[UIImage]
    
    var imageSrcURLArray:[URL]?
    @State var focusedTransType:TransitionType?
    
    
    @State private var showTransitionMenu:Bool = false
    @State private var crtScrollPosition = 0.0
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    //timeBar
                    ScrollViewReader { scrollViewProxy in
                        ScrollView([.horizontal], showsIndicators: true) {
                            
                        }.onChange(of: crtScrollPosition) { oldValue, newValue in
                            scrollViewProxy.scrollTo(newValue, anchor: .top)
                        }
                    }
                    
                    ScrollViewReader { ScrollViewProxy in
                        ScrollView([.horizontal], showsIndicators: true) {
                            HStack(spacing: 2, content: {
                                ForEach(Array(imageArray.enumerated()), id: \.offset) {index, image in
                                    ClipView(image: image, hasTransitionBtn: index > 0, showTransitionMenu: $showTransitionMenu)
                                }
                            })
                            .background(GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollViewOffsetKey.self, value: geo.frame(in: .global).minY)
                            })
                            .padding(EdgeInsets(top: 0, leading: geometry.size.width/2.0, bottom: 0, trailing: geometry.size.width/2.0))
                        }
                        .onPreferenceChange(ScrollViewOffsetKey.self) { value in
                            crtScrollPosition = value
                        }
                        .frame(height: kThumbImgSize.height)
                    }
                    
                    Spacer().frame(height: 100)
                    
                }
                
                if showTransitionMenu {
                    TransitionMenuView(showTransitionMenu: $showTransitionMenu, focusedTransType: $focusedTransType)
                        .frame(height: 150)
                        .edgesIgnoringSafeArea(.all)
                        .background(Color("BlackColor_27"))
                        .transition(.move(edge: .bottom))
                        .animation(.easeInOut, value: 0.3)
                }
            }
        }
    }
}
 
struct ClipView: View {
    let path:URL?
    let hasTransitionBtn:Bool
    @Binding var showTransitionMenu:Bool
    @State var transType = TransitionType.None
    @State var thumbImages:[UIImage] = []
    
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
            
            if hasTransitionBtn {
                Button {
                    showTransitionMenu = true
                } label: {
                    Image(systemName: transType == .None ? "checkmark.square" : "checkmark.square.fill")
                }
                .frame(width: kTransitionBtnSize.width, height: kTransitionBtnSize.height)
                .offset(x: -kTransitionBtnSize.width/2.0)
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

struct TransitionMenuView: View {
    @Binding var showTransitionMenu:Bool
    @Binding var focusedTransType:TransitionType?
    var body: some View {
        VStack(){
            ScrollView([.horizontal]) {
                HStack(spacing: 15, content: {
                    ForEach(TransitionType.allCases) { type in
                        TransitionItemView(type: type, focusedTransType: $focusedTransType)
                    }
                })
            }
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            
            Button {
                showTransitionMenu = false
            } label: {
                Text("Done")
            }.padding(10)
            
            Spacer()
        }
    }

}

struct TransitionItemView: View {
    let type:TransitionType
    @Binding var focusedTransType:TransitionType?
    var body: some View {
        VStack(spacing: 3) {
            Button {
                focusedTransType = type
            } label: {
                Image("avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedTransType == type ? Color.red : Color.clear, lineWidth: 2)
            }
            .padding(2)
            
            Text(type.rawValue)
                .font(.system(size: 14))
                .lineLimit(1)
                .frame(width: 56)
        }
    }
}


// Custom PreferenceKey to track the scroll offset
struct ScrollViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

//#Preview {
//    EditorToolView(imageSrcURLArray: [Bundle.main.url(forResource: "pic_1", withExtension: "jpg")!,
//                                      Bundle.main.url(forResource: "pic_2", withExtension: "jpg")!,
//                                      Bundle.main.url(forResource: "pic_3", withExtension: "jpg")!,
//                                      Bundle.main.url(forResource: "pic_4", withExtension: "jpg")!])
//}

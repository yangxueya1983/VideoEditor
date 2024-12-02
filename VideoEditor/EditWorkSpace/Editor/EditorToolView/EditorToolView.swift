//
//  EditorToolView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-08-20.
//

import SwiftUI


struct EditorToolView: View {
    @Binding var imageArray:[UIImage]

    @State var focusedTransType:TransitionType?
    @State private var showTransitionMenu:Bool = false
    @State private var crtScrollPosition = 0.0
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
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
                    }
                    
                    Spacer().frame(height: 150)
                    
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

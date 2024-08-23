//
//  EditorToolView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-08-20.
//

import SwiftUI
let kThumbImgSize = CGSize(width: 40, height: 40)
struct EditorToolView: View {
    let imageSrcURLArray = [Bundle.main.url(forResource: "pic_1", withExtension: "jpg")!,
                            Bundle.main.url(forResource: "pic_2", withExtension: "jpg")!,
                            Bundle.main.url(forResource: "pic_3", withExtension: "jpg")!,
                            Bundle.main.url(forResource: "pic_4", withExtension: "jpg")!]
    @State var showTransitionMenu:Bool = false
    @State var focusedTransType:TransitionType?
    
    var body: some View {
        ZStack {
            Spacer()
            ScrollView([.horizontal], showsIndicators: true) {
                HStack(spacing: 2, content: {
                    ForEach(Array(imageSrcURLArray.enumerated()), id: \.offset) {index, imgUrl in
                        ClipView(path: imgUrl, hasTransitionBtn: index > 0, showTransitionMenu: $showTransitionMenu)
                    }
                })
                HStack {
                    //music
                }
            }
            .frame(height: kThumbImgSize.height)
            
            Spacer().frame(height: 100)
            
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
 
struct ClipView: View {
    let path:URL
    let hasTransitionBtn:Bool
    @Binding var showTransitionMenu:Bool
    @State var transType = TransitionType.None
    @State var thumbImages:[UIImage] = []
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
                .frame(width: 20, height: 20)
                .offset(x: -10)
            }
        }
        .task {
            if thumbImages.count == 0 {
                thumbImages = getThumbImages(filePath: path)
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


#Preview {
    EditorToolView()
}

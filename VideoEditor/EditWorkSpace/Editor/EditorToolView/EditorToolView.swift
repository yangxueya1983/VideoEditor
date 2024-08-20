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

    var body: some View {
//        Spacer()
//        if let bundleURL = Bundle.main.url(forResource: "pic_1", withExtension: "jpg") ,
//           let image = UIImage(contentsOfFile: bundleURL.path()) {
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFill()
//                .frame(width: 100, height: 100)
//                .clipped()
//                .background(.red)
//        } else {
//            Text("Image not found in bundle")
//        }
//        Spacer()

        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            HStack {
                ForEach(imageSrcURLArray, id: \.self) { imgUrl in
                    ClipView(path: imgUrl)
                }
            }
        }
    }
}

struct ClipView: View {
    let path:URL
    @State var thumbImages:[UIImage] = []
    var body: some View {
        HStack(spacing: 0, content: {
            ForEach(thumbImages, id: \.self) { item in
                Image(uiImage:item)
                    .resizable()
                    .scaledToFill()
                    .frame(width: kThumbImgSize.width, height: kThumbImgSize.height)
                    .clipped()
                    
            }
        })
        .task {
            if thumbImages.count == 0 {
                thumbImages = getThumbImages(filePath: path)
                print("yxy thumbImgcount = \(thumbImages.count)")
            }
        }
    }
    
    func getThumbImages(filePath:URL) -> [UIImage] {
        var imgArr:[UIImage] = []
        for _ in 0..<3 {
            let img = UIImage(contentsOfFile: filePath.path())
            if let img {
                imgArr.append(img)
            }
        }
        return imgArr
    }
    
}

#Preview {
    EditorToolView()
}

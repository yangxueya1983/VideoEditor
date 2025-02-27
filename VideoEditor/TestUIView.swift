//
//  TestUIView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-10-31.
//

import SwiftUI
import OSLog
class TestTask {
    let id: UUID = UUID()
    let name: String
    var isDone: Bool = false
    init(name: String) {
        self.name = name
    }
}

struct TestUIView : View {
    var body: some View {
        EmptyView()
            .task {
                let urls = [URL(string: "https://images.pexels.com/photos/1108099/pexels-photo-1108099.jpeg")!,
                            URL(string: "https://images.pexels.com/photos/1619690/pexels-photo-1619690.jpeg")!,
                            URL(string: "https://images.pexels.com/photos/13982096/pexels-photo-13982096.jpeg")!]
            }
            .frame(height: 100)
    }
}



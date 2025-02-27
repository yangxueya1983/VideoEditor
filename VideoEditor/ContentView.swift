//
//  ContentView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [EditSession]
    let transitionTypes: [TransitionType] = Array(TransitionType.allCases.dropFirst())
    let defaultImagePath = Bundle.main.url(forResource: "pic_1", withExtension: "jpg")!
    
    var body: some View {
        NavigationSplitView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0, content: {
                        ForEach(transitionTypes, id: \.self) { type in
                            NavigationLink {
                                VideoEditView(transitionType: type)
                            } label: {
                                TransitionTypeView(type: type)
                            }
                        }
                    })
                }
                
                if items.isEmpty {
                    ContentUnavailableView.init("No items", image: "book.pages.fill", description: Text("Click the plus button to add items"))
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                VideoEditView(storageSession: item)
                            } label: {
                                HStack {
                                    AsyncImage(url: item.photos.first(where: {$0.index == 0})?.url ?? defaultImagePath) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.red
                                    }
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(.rect(cornerRadius: 8))
                                        
                                    Text(item.createdAt, format: Date.FormatStyle(date: .numeric, time: .standard))
                                }
                                
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    
                    NavigationLink {
                        VideoEditView()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
                try? modelContext.save()
            }
        }
    }
}

struct TransitionTypeView: View {
    let type:TransitionType
    var body: some View {
        VStack(spacing: 3) {
            Image(uiImage:UIImage(named: type.thumbImgName) ?? UIImage())
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .padding(.bottom, 0)
            
            Text(type.rawValue)
                .font(.system(size: 14))
                .lineLimit(1)
                .frame(width: 80)
            
            Spacer()
        }
        .frame(height: 100)
    }
}

#Preview {
    ContentView()
}

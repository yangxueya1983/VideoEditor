//
//  ContentView.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import SwiftUI
import SwiftData


struct DetailView: View {
    var item: EditSession

    var body: some View {
        Text("Item at \(Date(), format: Date.FormatStyle(date: .numeric, time: .standard))")
            .task {
                item.createdAt = Date()
            }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [EditSession]
    let transitionTypes: [TransitionType] = Array(TransitionType.allCases.dropFirst())
    
    var body: some View {
        NavigationSplitView {
            VStack {
                HStack(spacing: 0, content: {
                    ForEach(transitionTypes, id: \.self) { type in
                        TransitionTypeView(type: type)
                    }
                })
                
                if items.isEmpty {
                    ContentUnavailableView.init("No items", image: "book.pages.fill", description: Text("Click the plus button to add items"))
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                VideoEditView(editSession: item, needPreLoad: true)
                            } label: {
                                HStack {
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
                        VideoEditView(editSession: EditSession())
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
            try? modelContext.save()
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
        .modelContainer(for: Item.self, inMemory: true)
}

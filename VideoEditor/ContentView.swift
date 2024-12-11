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
    
    var body: some View {
        NavigationSplitView {
            VStack {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            VideoEditView(editSession: item, needPreLoad: true)
                        } label: {
                            Text(item.createdAt, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        
                        NavigationLink {
                            VideoEditView(editSession: EditSession.testSession())
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
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
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

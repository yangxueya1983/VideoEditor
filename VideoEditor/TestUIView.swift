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
                
                let result = await downloadImages(imageURLs: urls)
                Logger.viewCycle.debug("result: \(result.count)")
//                let tasks = Array(1...10).map{
//                    return TestTask(name: "Task \(String($0))")
//                }
//                
//                let doneTasks = try? await runGroupTasks(tasks: tasks)
//                if let doneTasks {
//                    let taskNames = doneTasks.map{$0.name}
//                    Logger.viewCycle.debug("doneTasks: \(taskNames)")
//                }
                

            }
            .frame(height: 100)
    }
    
    func runGroupTasks(tasks: [TestTask]) async throws -> [TestTask] {
        var results: [TestTask] = Array(repeating: TestTask(name: ""), count: tasks.count)
        return try await withThrowingTaskGroup(of: (Int,TestTask).self) { group in
            
            for (idx,task) in tasks.enumerated() {
                group.addTask {
                    let ret = try await runSingleTask(task:task)
                    return (idx, ret)
                }
            }
            
            for try await (idx,t) in group {
                results[idx] = t
            }
            
//            results.sort(by: { $0.name < $1.name })
            
            return results
        }
    }
    
    func runSingleTask(task: TestTask) async throws -> TestTask {
        let randomTime = UInt64.random(in: 1...10)
        try await Task.sleep(nanoseconds: randomTime)
        task.isDone = true
        Logger.viewCycle.debug("\(task.name) is done")
        return task
    }
}



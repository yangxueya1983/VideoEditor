//
//  VideoEditorTests.swift
//  VideoEditorTests
//
//  Created by NancyYang on 2024-07-29.
//

import XCTest
@testable import VideoEditor

final class VideoEditorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testGenerateImage() throws  {
        let size = CGSizeMake(100, 100)
        let radius = min(size.width, size.height) / 2
        let process = 0.5
         
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let ctx = context.cgContext
            let center = CGPointMake(size.width/2, size.height/2)
            ctx.move(to: center)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * Double.pi * process, clockwise: false)
            ctx.closePath()
            ctx.fillPath()
        }
        
        let savePath = FileManager.default.temporaryDirectory.appendingPathComponent("out.png");
        try image.pngData()!.write(to: savePath)
    }

}

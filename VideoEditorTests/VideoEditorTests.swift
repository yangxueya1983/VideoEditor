//
//  VideoEditorTests.swift
//  VideoEditorTests
//
//  Created by NancyYang on 2024-07-29.
//

import XCTest
import simd
import MetalKit
import OSLog
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
    
    func test3DCoordinateRotation() throws {
        let screenWidth : Float = 200
        let screenHeight: Float = 100
        let aspectRatio: Float = screenWidth / screenHeight
        let fov : Float = .pi / 2
        let nearPlane : Float = 0.1
        let farPlane : Float  = 100

        let projectionMatrix = simd_float4x4(
            simd_float4(1 / (aspectRatio * tan(fov / 2)), 0, 0, 0),
            simd_float4(0, 1 / tan(fov / 2), 0, 0),
            simd_float4(0, 0, -(farPlane + nearPlane) / (farPlane - nearPlane), -1),
            simd_float4(0, 0, -2 * farPlane * nearPlane / (farPlane - nearPlane), 0)
        )
        
        let leftTop = simd_float3(-1 * aspectRatio, 1, -1)
        let rightTop = simd_float3(aspectRatio, 1, -1)
        let center = simd_float3(0,0,-3)
        
        let axisOfRotation = simd_normalize(simd_float3(0, 1, 0))
        for i in 0...100 {
            let percent = Float(i) / 100
            let angle : Float = .pi  * percent
            let quaternion = simd_quaternion(angle, axisOfRotation)
            let translatePosition = leftTop - center
            let rotateVector = simd_act(quaternion, translatePosition)
            let finalCoordinate = rotateVector + center
            
//            Logger.viewCycle.debug("\(percent) => ( \(finalCoordinate.x) \(finalCoordinate.y) \(finalCoordinate.z)")
            let homogenousVector = simd_float4(finalCoordinate, 1.0)
            
            let projectVector = projectionMatrix * homogenousVector
            let ndcVector = projectVector / projectVector.w
//            Logger.viewCycle.debug("ndc vector : \(ndcVector.x) \(ndcVector.y)")
            
            let screenX = (ndcVector.x + 1) / 2 * screenWidth
            let screenY = (1 - ndcVector.y) / 2 * screenHeight
            
            Logger.viewCycle.debug("\(percent) -> ( \(screenX) : \(screenY)  )")
        }
    }

}

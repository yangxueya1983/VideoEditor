//
//  TestEditingAPIs.swift
//  VideoEditorTests
//
//  Created by Yu Yang on 2024-08-17.
//

import Foundation
import XCTest
import AVFoundation
@testable import VideoEditor


final class EditAPITest : XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func createPhotoItem(name: String, ext: String) -> PhotoItem? {
        guard let  url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return nil
        }
        
        let duration = CMTime(value: 3, timescale: 1)
        let photoItem = PhotoItem(url: url, image: UIImage(), duration: duration)
        return photoItem
    }
    
    func getOutputURL() -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
    }
    
    func testConcatenate() async throws {
        // create 3 photo items
        let photoItem1 = createPhotoItem(name: "pic_1", ext: "jpg")
        let photoItem2 = createPhotoItem(name: "pic_2", ext: "jpg")
        let photoItem3 = createPhotoItem(name: "pic_3", ext: "jpg")
        guard let photoItem1, let photoItem2, let photoItem3 else {
            XCTAssert(false, "can't find the item")
            return
        }
        
        let photoItems = [photoItem1, photoItem2, photoItem3]
        
        let outURL = getOutputURL()
        print("the output will be dumpted to \(outURL)")
        let error = await SessionUtilties.concatenatePhotoWithoutTransition(width: 720, height: 480, photoItems: photoItems, outURL: outURL)
        if let error {
            print("the error is \(error)")
        } else {
            print("the export succeed")
        }
    }
    
    func testAddAudio() throws {
        _ = printAnimal(animal: dog)
        _ = printAnimal(animal: cat)
    }
    
    func testTransition1() async throws {
        let photoItem1 = createPhotoItem(name: "pic_1", ext: "jpg")
        let photoItem2 = createPhotoItem(name: "pic_2", ext: "jpg")
        
        guard let photoItem1, let photoItem2 else {
            XCTAssert(false)
            return
        }
        let session = EditSession()
        session.videoWidth = 720
        session.videoHeight = 480
        session.photos = [photoItem1, photoItem2]
        
        // create the transition action
        let config = TransitionCfg(item1Id: photoItem1.itemID, item2Id: photoItem2.itemID, type: .Opacity, duration: CMTime(value: 1, timescale: 1))
        session.transCfgs = [config]
        
        let outURL = getOutputURL()
        print("the generated video will be exported to \(outURL)")
        let error = try await SessionUtilties.concatenatePhotosWithTransition(sess: session, outURL: outURL)
        if let error {
            print("the error is \(error)")
        } else {
            print("the export succeed")
        }
    }
}

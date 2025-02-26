//
//  TestEditingAPIs.swift
//  VideoEditorTests
//
//  Created by Yu Yang on 2024-08-17.
//

import Foundation
import XCTest
import AVFoundation
import OSLog
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
        
        let photoItem = EditSession.getBundlePhotoItem(bundleUrl: url)
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
        Logger.viewCycle.debug("the output will be dumpted to \(outURL)")
        let error = await SessionUtilties.concatenatePhotoWithoutTransition(width: 720, height: 480, photoItems: photoItems, outURL: outURL)
        if let error {
            Logger.viewCycle.debug("the error is \(error)")
        } else {
            Logger.viewCycle.debug("the export succeed")
        }
    }
    
    func testAddAudio() throws {
        _ = printAnimal(animal: dog)
        _ = printAnimal(animal: cat)
    }
    
//    func testTransition1() async throws {
//        let photoItem1 = createPhotoItem(name: "pic_1", ext: "jpg")
//        let photoItem2 = createPhotoItem(name: "pic_2", ext: "jpg")
//        
//        guard let photoItem1, let photoItem2 else {
//            XCTAssert(false)
//            return
//        }
//        let session = EditSession()
//        session.videoWidth = 720
//        session.videoHeight = 480
//        session.photos = [photoItem1, photoItem2]
//        
//        // create the transition action
//        let config = TransitionCfg(item1Id: photoItem1.itemID, item2Id: photoItem2.itemID, type: .Opacity, duration: CMTime(value: 1, timescale: 1))
//        session.transCfgs = [config]
//        
//        let outURL = getOutputURL()
//        Logger.viewCycle.debug("the generated video will be exported to \(outURL)")
//        let error = try await SessionUtilties.concatenatePhotosWithTransition(sess: session, outURL: outURL)
//        if let error {
//            Logger.viewCycle.debug("the error is \(error)")
//        } else {
//            Logger.viewCycle.debug("the export succeed")
//        }
//    }
    
    func testSession() async throws {
        // create a session
        
        let getImage = { (name: String, ext: String) -> UIImage? in
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
                return nil
            }
            
            let image = UIImage(contentsOfFile: url.path())
            return image
        }
        
        let image1 = getImage("pic_1", "jpg")!
        let image2 = getImage("pic_2", "jpg")!
        let image3 = getImage("pic_3", "jpg")!
        let transitions: [TransitionType] = [.Dissolve, .MoveUp, .MoveDown]
        
        let createPhotoItem = { (name: String, image: UIImage) -> PhotoItem in
            let item = PhotoItem(cacheKey: name, image: image)
            return item
        }
        
        let photoItems : [PhotoItem] = [createPhotoItem("pic_1", image1), createPhotoItem("pic_2", image2), createPhotoItem("pic_3", image3)]
        
        for (index, photoItem) in photoItems.enumerated() {
            photoItem.transitionType = transitions[index]
        }
        
        let audioURL = Bundle.main.url(forResource: "Saddle of My Heart", withExtension: "mp3")!
        let audioItem = EditSession.getBundleAudioItem(bundleUrl: audioURL)
        
        let session = EditSession(photos: photoItems, audios: [audioItem])
        let outputPath = NSTemporaryDirectory().appending("output.mp4")
        Logger.viewCycle.debug("will export to \(outputPath)")
        if FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.removeItem(atPath: outputPath)
        }
        let outURL = URL(fileURLWithPath: outputPath)
        
        let error = await VEUtil.createVideoForSession(sess: session, outputURL:outURL)
        print(error.debugDescription)
    }
}

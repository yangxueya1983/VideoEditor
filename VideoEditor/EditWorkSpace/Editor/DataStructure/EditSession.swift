//
//  EditSession.swift
//  VideoEditor
//
//  Created by Yu Yang on 2024-08-09.
//

import Foundation
import PhotosUI
import SwiftyJSON
import SwiftData

@Model
class EditSession {
    @Attribute(.unique) var id: UUID
    var photos: [PhotoItem] = []
    var audios: [AudioItem] = []
    var transCfgs: [TransitionCfg] = []
    
    init(id: UUID = UUID(),
         photos: [PhotoItem] = [],
         audios: [AudioItem] = [],
         transitions: [TransitionCfg] = [],
         videoWidth: Int = 1080,
         videoHeight: Int = 1920) {
        self.id = id
        self.photos = photos
        self.audios = audios
        self.transCfgs = transitions
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
    }

    var videoWidth: Int = 1080
    var videoHeight: Int = 1920
    
    func loadWithImages(images:[UIImage]) -> Bool {
        return true
    }

    func hasPhoto() -> Bool {
        return photos.count > 0
    }
    
    func hasTransition() -> Bool {
        if transCfgs.isEmpty {
            return false
        }
        
        for t in transCfgs {
            if t.type != .None {
                return true
            }
        }

        return false
    }
    
    func isValid() -> Bool {
        return true
    }
    
    func check() -> Bool {
        // TODO: implement this
        
        // TODO: audio timerange should have no overlap
        return true
    }
    
    func groupPhotoItemsWithoutTransition() -> ([[PhotoItem]], [TransitionCfg]) {
        var groups: [[PhotoItem]] = []
        var trans: [TransitionCfg] = []
        
        var oneGroup: [PhotoItem] = []
        for itm in photos {
            if oneGroup.isEmpty {
                oneGroup.append(itm)
                continue
            }
            
            assert(!oneGroup.isEmpty)
            let prvItem = oneGroup.last!
            let cfg = findTransitionType(item1: prvItem, item2: itm)
            guard let cfg = cfg else {
                assert(false, "the transition type can not be found")
            }
            
            if cfg.type == .None {
                oneGroup.append(itm)
            } else {
                groups.append(oneGroup)
                oneGroup.removeAll()
                trans.append(cfg)
                oneGroup.append(itm)
            }
        }
        
        if !oneGroup.isEmpty {
            groups.append(oneGroup)
            oneGroup.removeAll()
        }
        
        return (groups, trans)
    }
    
    
    private func findTransitionType(item1: PhotoItem, item2: PhotoItem) -> TransitionCfg? {
        let id1 = item1.itemID
        let id2 = item2.itemID
        
        for itm in transCfgs {
            if itm.item1Id == id1 && itm.item2Id == id2 {
                return itm
            }
        }
        
        return nil
    }
    
    func exportVideo(outputURL: URL) async -> Error? {
        let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent(Date().formattedDateString() + "video.mp4")
        let editImages = photos.map{$0.image}
        let error = await VEUtil.createVideoFromImages(images: editImages, outputURL: videoURL)
        
        if let error {
            return error
        } else {
            print("Video created successfully at \(videoURL)")
            if audios.count > 0 {
                if let audioURL = audios.first?.url {
                    let error = await VEUtil.addAudioToVideo(videoURL: videoURL, audioURL: audioURL, outputURL: outputURL)
                    if let error {
                        return error
                    }
                    print("Video added Audio successfully at \(outputURL)")
                } else {
                    return NSError(domain: "", code: 0, userInfo: ["error" : "Resource not found."])
                }
            } else {
                do {
                    try FileManager.default.moveItem(at: videoURL, to: outputURL)
                } catch {
                    return error
                }
            }
            
        }
        return nil
    }
}

extension EditSession {
    static func testSession() -> EditSession {
        let imageSrcURLArray = Array(1...3).map { i in
            let path = Bundle.main.url(forResource: "pic_\(i)", withExtension: "jpg")!
            return path
        }
        let audioSrcURLArray = [Bundle.main.url(forResource: "Saddle of My Heart", withExtension: "mp3")!]
                                
        let editSession = EditSession()
        
        //photos
        let photoArr = imageSrcURLArray.map { path in
            PhotoItem(url: path,
                      image: UIImage(contentsOfFile: path.path())!,
                      duration: CMTime(value: 3, timescale: 1))
        }
        editSession.photos = photoArr
        
        //audios
        let audioArr = audioSrcURLArray.map { path in
            let audioItem = AudioItem(url: path,
                                      selectRange: CMTimeRange(start: .zero, duration: .invalid),
                                      positionTime: .zero)
            return audioItem
        }
        editSession.audios = audioArr
        
        
        return editSession
    }
}

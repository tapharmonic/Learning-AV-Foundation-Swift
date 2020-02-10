//
//  MIT License
//
//  Copyright (c) 2014 Bob McCune http://bobmccune.com/
//  Copyright (c) 2014 TapHarmonic, LLC http://tapharmonic.com/
//  Copyright (c) 2020 Jan Weiß http://geheimwerk.de/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import AppKit
import AVFoundation
import AVKit


enum LoadingStates {
    case loading
    case loadingAndSignaling
    case ended
}


class Document: NSDocument, ExportWindowControllerDelegate {
	var asset: AVAsset? = nil
	var playerItem: AVPlayerItem? = nil
	var observer: NSKeyValueObservation? = nil
	var chapters: [Chapter] = []
	var exportSession: AVAssetExportSession? = nil
	var exportController: ExportWindowController? = nil
    
    var loadingState: LoadingStates = .loading
    let loadingSignalDelay = 1.0
    
    @objc dynamic var loadingSignal: Bool {
        get {
            return (loadingState == .loadingAndSignaling)
        }
    }
    
    @objc dynamic var noVideoTracks = false
    @objc dynamic var enableNoVideoSignaling = false
    @objc dynamic var unplayableFile = false

    @IBOutlet var playerView: AVPlayerView?

	
	// MARK: - NSDocument Methods

	override var windowNibName: NSNib.Name? {
        return NSNib.Name("Document")
    }

	override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + loadingSignalDelay) {
            [weak self] in
            if self?.loadingState == .loading {
                self?.loadingState = .loadingAndSignaling
            }
        }

		if let fileURL = self.fileURL {
			self.setupPlaybackStackWithURL(url: fileURL)
		}
    }

    // MARK: - Setup

    func setupPlaybackStackWithURL(url: URL) {
        self.asset = AVAsset(url: url)
        guard let asset = self.asset else {
            return
        }
        
        let keys: [String] = ["playable", "hasProtectedContent", "commonMetadata", "availableChapterLocales"]       // 3
        
        self.playerItem = AVPlayerItem(asset: asset)          // 4
        
        // If needed, configure player item here (example: adding outputs, setting text style rules, selecting media options) before associating it with a player.
        
        asset.loadValuesAsynchronously(forKeys: keys) {       // 4
            DispatchQueue.main.async {
                // The asset invokes its completion handler on an arbitrary queue when loading is complete.
                // Because we want to access our AVPlayer in our ensuing set-up, we must dispatch our handler to the main queue.
                self.setUpPlayback(ofAsset: asset, withKeys: keys)
            }
        }
    }

    func setUpPlayback(ofAsset asset: AVAsset, withKeys keys: [String]) {
        // First test whether the values of each of the keys we need have been successfully loaded.
        for key in keys {
            var error: NSError? = nil
            
            if asset.statusOfValue(forKey: key, error: &error) == .failed {
                self.stopLoadingAnimation()
                
                if let error = error {
                    self.handleError(error)
                }
                
                return
            }
        }
        
        if !asset.isPlayable || asset.hasProtectedContent {
            // We can't play this asset. Show the "Unplayable Asset" label.
            self.stopLoadingAnimation()
            self.unplayableFile = true
            
            return
        }
        
        // We can play this asset.
        
        if asset.tracks(withMediaType: AVMediaType.video).count == 0 {
            // This asset has no video tracks. Show the "No Video" label.
            self.noVideoTracks = true
        }
        
        guard let playerItem = self.playerItem else {
            return
        }
        
        self.observer = playerItem.observe(\.status, options: []) { // 5
            (playerItem, change) in
            self.setupUI(for: playerItem)
        }
        
        guard let playerView = self.playerView else {
            return
        }
        
        playerView.player = AVPlayer(playerItem: playerItem)
        playerView.showsSharingServiceButton = true
    }
	
	func setupUI(for playerItem: AVPlayerItem) {
		guard playerItem.status == .readyToPlay else {
            if playerItem.status == .failed {
                self.stopLoadingAnimation()
                
                if let error = playerItem.error {
                    self.handleError(error)
                }
			}
			
			return
		}
            
        self.stopLoadingAnimation()
        
		guard let asset = self.asset else {
			return
		}
		
		let title = self.titleForAsset(asset: asset)
		if let title = title {
			self.windowForSheet?.title = title
		}
		self.chapters = self.chaptersForAsset(asset: asset)
		
		// Create action menu if chapters are available.
		if self.chapters.count > 0 {
			self.setupActionMenu()
		}
		
		self.observer?.invalidate()
	}
	
    func titleInMetadata(metadata: [AVMetadataItem]) -> String? {
		let items = AVMetadataItem.metadataItems(from: metadata,
												 withKey: AVMetadataKey.commonKeyTitle,
												 keySpace: AVMetadataKeySpace.common)

		return items.first?.stringValue                               // 2
    }

    func titleForAsset(asset: AVAsset) -> String? {
		let title = self.titleInMetadata(metadata: asset.commonMetadata)          // 3
        if title != nil && title != "" {
            return title
        }
		else {
			return nil
		}
    }

    func chaptersForAsset(asset: AVAsset) -> [Chapter] {
        let languages = NSLocale.preferredLanguages                     // 1

		let metadataGroups = asset.chapterMetadataGroups(bestMatchingPreferredLanguages: languages)

		var chapters: [Chapter] = []
		
		var i: UInt = 0

		for group in metadataGroups {
            let time: CMTime = group.timeRange.start
            let number: UInt = i + 1
			let title = self.titleInMetadata(metadata: group.items) ?? "untitled chapter"

			let chapter = Chapter(time: time, number: number, title: title)

            chapters.append(chapter)
			i += 1
		}
		
        return chapters
    }

    // MARK: - Chapter Navigation

    func setupActionMenu() {
		guard let playerView = self.playerView else {
			return
		}
		
        let menu = NSMenu()                                   // 1
		menu.addItem(NSMenuItem(title: "Previous Chapter",
								action: #selector(Document.previousChapter),
								keyEquivalent: ""))
		menu.addItem(NSMenuItem(title: "Next Chapter",
								action: #selector(Document.nextChapter),
								keyEquivalent: ""))

        playerView.actionPopUpButtonMenu = menu                           // 2
    }

    @objc func previousChapter(_ sender: AnyObject) {
		self.skipToChapter(chapter: self.findPreviousChapter())                        // 1
    }

    @objc func nextChapter(_ sender: AnyObject) {
		self.skipToChapter(chapter: self.findNextChapter())                            // 2
    }

    func skipToChapter(chapter: Chapter?) {                                // 3
		guard let playerItem = self.playerItem, let chapter = chapter else {
			return
		}

		playerItem.seek(to: chapter.time) { (done: Bool) in
			self.playerView?.flashChapterNumber(Int(chapter.number),
												chapterTitle: chapter.title)
		}
    }

    func findPreviousChapter() -> Chapter? {
		guard let playerItem = self.playerItem else {
			return nil
		}
		
        let playerTime = playerItem.currentTime()
		let prerollTime = CMTimeMakeWithSeconds(3, preferredTimescale: playerTime.timescale)
        let searchEndTime = CMTimeMaximum(CMTimeSubtract(playerTime, prerollTime), CMTime.zero)     // 1
		let pastTime = CMTime.negativeInfinity
		
		let timeRange = CMTimeRangeMake(start: pastTime, duration: searchEndTime)         // 2

		return self.findChapter(timeRange: timeRange, reverse: true)             // 3
    }

    func findNextChapter() -> Chapter? {
		guard let playerItem = self.playerItem else {
			return nil
		}
		
    	let currentTime = playerItem.currentTime()                       // 4
		let futureTime = CMTime.positiveInfinity

		let timeRange = CMTimeRangeFromTimeToTime(start: currentTime, end: futureTime)       // 5

		return self.findChapter(timeRange: timeRange, reverse: false)              // 6
    }
	
    func findChapter(timeRange: CMTimeRange, reverse: Bool) -> Chapter? {
        var matchingChapter: Chapter? = nil
		
		for chapter in reverse ? self.chapters.reversed() : self.chapters {
			if chapter.isIn(timeRange) {                   // 8
                matchingChapter = chapter
                break
            }
        }

        return matchingChapter                                                 // 9
    }
	
	// MARK: - File handling
	
	override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        return
    }

    // MARK: - Trimming

    @IBAction func startTrimming(_ sender: AnyObject) {
		self.playerView?.beginTrimming(completionHandler: nil)
    }

	func validateUserInterfaceItem(item: NSValidatedUserInterfaceItem) -> Bool {
		if item.action == #selector(Document.startTrimming) {
    		return self.playerView?.canBeginTrimming ?? false
		}
		
		return true
	}
	
    // MARK: - Exporting

	class func temporaryDirectory(forURL baseURL: URL) throws -> URL {
		do {
			return try FileManager.default.url(for: .itemReplacementDirectory,
											   in: .userDomainMask,
											   appropriateFor: baseURL,
											   create: true)
		}
		catch {
			throw error
		}
	}
	
    @IBAction func startExporting(_ sender: AnyObject) {
		guard let asset = self.asset,
			let windowForSheet = self.windowForSheet else {
			return
		}
		
    	self.playerView?.player?.pause()                                         // 1

		let savePanel = NSSavePanel()

		savePanel.beginSheetModal(for: windowForSheet) { (result: NSApplication.ModalResponse) in

			if result == NSApplication.ModalResponse.OK {
				guard let finalURL = savePanel.url else {
					return
				}
				
				// Order out save panel as the export window will be shown.
				savePanel.orderOut(nil)
				
				// WWDX 2010, Session 407
				// A Word on Error Handling
				// Handle failures gracefully
				// • AVAssetExportSession will not overwrite files
				// • AVAssetExportSession will not write files outside of your sandbox [kinda obvious, ed.]
				
				let temporaryDirectoryURL: URL
				do {
					try temporaryDirectoryURL = Document.temporaryDirectory(forURL: finalURL)
				}
				catch {
					self.handleError(error)
					
					self.exportSession = nil
					
					return
				}
				
				let finalName = finalURL.lastPathComponent
				let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(finalName)
				Swift.print("Temporary media export file: \(temporaryFileURL)")

                let preset = AVAssetExportPresetAppleM4V720pHD
                self.exportSession =                                            // 2
					AVAssetExportSession(asset: asset,
										 presetName: preset)
				guard let exportSession = self.exportSession else {
					return
				}
				
				let supportedFileType = exportSession.supportedFileTypes.first
				Swift.print(supportedFileType ?? "<nil>")

				guard let playerItem = self.playerItem else {
					return
				}
				
                let startTime = playerItem.reversePlaybackEndTime
                let endTime = playerItem.forwardPlaybackEndTime
				let timeRange = CMTimeRangeMake(start: startTime, duration: endTime)    // 3
				
                // Configure the export session.                                 // 4
                exportSession.timeRange = timeRange
                exportSession.outputFileType =
                    exportSession.supportedFileTypes.first
				exportSession.outputURL = temporaryFileURL
				
                self.exportController = ExportWindowController()
				guard let exportController = self.exportController else {
					return
				}
				
                exportController.exportSession = exportSession
                exportController.delegate = self
				
				guard let exportControllerWindow = exportController.window else {
					return
				}
				
				windowForSheet.beginSheet(exportControllerWindow,    // 5
					completionHandler: nil)

				exportSession.exportAsynchronously(completionHandler: {
					// Tear down.                                               // 6
					if exportSession.status == AVAssetExportSession.Status.failed,
						let error = exportSession.error {
						self.handleError(error)
					}
					else if exportSession.status == AVAssetExportSession.Status.completed {
						do {
							try _ = FileManager.default.replaceItemAt(finalURL,
																	  withItemAt: temporaryFileURL,
																	  backupItemName: nil,
																	  options: .usingNewMetadataOnly)
						}
						catch {
							self.handleError(error)
						}
					}
					
					// Doing the following last results in a less jarring visual experience.
					// Doing this first would result in the `exportControllerWindow` retracting
					// and, if the alert sheet above needs to be displayed,
					// it sliding down immediatly afterwards leading to a fast yoyo-like motion.
					DispatchQueue.main.async(execute: {
						if let exportControllerWindow = exportController.window  {
							windowForSheet.endSheet(exportControllerWindow)
						}
					})

					self.exportController = nil
					self.exportSession = nil
				})
            }
        }
    }
	
	func exportDidCancel() {
		self.exportSession?.cancelExport()      // 7
	}
	

    // MARK: - UI

    func stopLoadingAnimation() {
        DispatchQueue.main.async {
            self.loadingState = .ended
        }
    }

}


// MARK: - Utility

extension NSDocument {
	
	func handleError(_ error: Error) {
		DispatchQueue.main.async {
			// `self.windowForSheet` must be accessed from the main thread only.
			guard let windowForSheet = self.windowForSheet else {
				return
			}
            
            self.presentError(error,
                              modalFor: windowForSheet,
                              delegate: nil,
                              didPresent: nil,
                              contextInfo: nil)
		}
	}
	
}

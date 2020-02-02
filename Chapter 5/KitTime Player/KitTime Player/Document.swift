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


let STATUS_KEY = "status"


class Document: NSDocument, THExportWindowControllerDelegate {
	var asset: AVAsset? = nil
	var playerItem: AVPlayerItem? = nil
	var chapters: [Chapter] = []
	var exportSession: AVAssetExportSession? = nil
	var exportController: THExportWindowController? = nil

	@IBOutlet var playerView: AVPlayerView?;

	
	// MARK: - NSDocument Methods

	override var windowNibName: NSNib.Name? {
        return NSNib.Name("Document")
    }

	override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
		
		if let fileURL = self.fileURL {
			self.setupPlaybackStackWithURL(url: fileURL)
		}
    }

    // MARK: - Setup

    func setupPlaybackStackWithURL(url: URL) {
		guard let playerView = self.playerView else {
			return
		}

		self.asset = AVAsset(url: url)
		guard let asset = self.asset else {
			return
		}

        let keys: [String] = ["commonMetadata", "availableChapterLocales"]       // 3

		self.playerItem = AVPlayerItem.init(asset: asset,          // 4
                               automaticallyLoadedAssetKeys: keys)
		guard let playerItem = self.playerItem else {
			return
		}

        playerItem.addObserver(self,                                       // 5
                          forKeyPath:STATUS_KEY,
						  options:[], context:nil)

        playerView.player = AVPlayer.init(playerItem: self.playerItem)
        playerView.showsSharingServiceButton = true
    }

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard self.playerItem?.status == AVPlayerItem.Status.readyToPlay,
			let asset = self.asset else {
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
		
        self.playerItem?.removeObserver(self, forKeyPath:STATUS_KEY)
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

			let chapter = Chapter.init(time: time, number: number, title: title)

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
		let preroll = CMTimeMake(value: 3, timescale: 1)
        let currentTime = CMTimeSubtract(playerTime, preroll)      // 1
		let pastTime = CMTime.negativeInfinity

		let timeRange = CMTimeRangeMake(start: pastTime, duration: currentTime)         // 2

		return self.findChapter(timeRange: timeRange, reverse: true)             // 3
    }

    func findNextChapter() -> Chapter? {
		guard let playerItem = self.playerItem else {
			return nil
		}
		
    	let currentTime = playerItem.currentTime                       // 4
		let futureTime = CMTime.positiveInfinity

		let timeRange = CMTimeRangeMake(start: currentTime(), duration: futureTime)       // 5

		return self.findChapter(timeRange: timeRange, reverse: false)              // 6
    }
	
    func findChapter(timeRange: CMTimeRange, reverse: Bool) -> Chapter? {
        var matchingChapter: Chapter? = nil
		
		for chapter in self.chapters.reversed() {
			if chapter.isIn(timeRange) {                   // 8
                matchingChapter = chapter
                break
            }
        }

        return matchingChapter                                                 // 9
    }
	
	// MARK: - Movie Modernization
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

    @IBAction func startExporting(_ sender: AnyObject) {
		guard let windowForSheet = self.windowForSheet,
			let asset = self.asset else {
			return
		}
		
    	self.playerView?.player?.pause()                                         // 1

		let savePanel = NSSavePanel()

		savePanel.beginSheetModal(for: windowForSheet) { (result: NSApplication.ModalResponse) in

			if result == NSApplication.ModalResponse.OK {
                // Order out save panel as the export window will be shown.
                savePanel.orderOut(nil)

                let preset = AVAssetExportPresetAppleM4V720pHD
                self.exportSession =                                            // 2
					AVAssetExportSession(asset: asset,
										 presetName: preset)
				guard let exportSession = self.exportSession else {
					return
				}
				
				//print("\(exportSession.supportedFileTypes.firstObject)")

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
				exportSession.outputURL = savePanel.url

                self.exportController = THExportWindowController()
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
					if let exportControllerWindow = exportController.window  {
						windowForSheet.endSheet(exportControllerWindow)
					}
					
                    self.exportController = nil
                    self.exportSession = nil
                })
            }
        }
    }
	
	func exportDidCancel() {
		self.exportSession?.cancelExport()                                      // 7
	}
	
}

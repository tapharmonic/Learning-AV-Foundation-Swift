//
//  MIT License
//
//  Copyright (c) 2015 Bob McCune http://bobmccune.com/
//  Copyright (c) 2015 TapHarmonic, LLC http://tapharmonic.com/
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
import AVFoundation

class SampleDataProvider {

    typealias SampleDataCompletionHandler = (NSData? -> Void)

    static func loadAudioSamplesFromAsset(asset: AVAsset, completionHandler: SampleDataCompletionHandler) {

        let tracks = "tracks"

        asset.loadValuesAsynchronouslyForKeys([tracks]) {

            let status = asset.statusOfValueForKey(tracks, error: nil)

            var sampleData: NSData? = nil

            if status == .Loaded {
                sampleData = readAudioSamplesFromAsset(asset)
            }

            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(sampleData)
            }
        }
    }

    static func readAudioSamplesFromAsset(asset: AVAsset) -> NSData? {

        guard let assetReader = try? AVAssetReader(asset: asset) else {
            print("Unable to create AVAssetReader")
            return nil
        }

        guard let track = asset.tracksWithMediaType(AVMediaTypeAudio).first else {
            print("No audio track found in asset")
            return nil
        }

        let outputSettings: [String: AnyObject] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16
        ]

        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        assetReader.addOutput(trackOutput)
        assetReader.startReading()

        let sampleData = NSMutableData()

        while assetReader.status == .Reading {
            if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                if let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer) {
                    let length = CMBlockBufferGetDataLength(blockBufferRef)
                    let sampleBytes = UnsafeMutablePointer<Int16>.alloc(length)
                    CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, sampleBytes)
                    sampleData.appendBytes(sampleBytes, length: length)
                }
            }
        }

        if assetReader.status == .Completed {
            return sampleData
        } else {
            print("Failed to read audio samples from asset.")
            return nil
        }
    }
}

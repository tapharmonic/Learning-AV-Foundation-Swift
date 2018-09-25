//
//  MIT License
//
//  Copyright (c) 2018 Bob McCune http://bobmccune.com/
//  Copyright (c) 2018 TapHarmonic, LLC http://tapharmonic.com/
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

    typealias SampleDataCompletionHandler = ((Data?) -> Void)

    static func loadAudioSamples(in asset: AVAsset, completionHandler: @escaping SampleDataCompletionHandler) {

        let tracks = "tracks"

        asset.loadValuesAsynchronously(forKeys: [tracks]) {

            let status = asset.statusOfValue(forKey: tracks, error: nil)

            var sampleData: Data? = nil

            if status == .loaded {
                sampleData = readAudioSamples(in:asset)
            }

            DispatchQueue.main.async {
                completionHandler(sampleData)
            }
        }
    }

    static func readAudioSamples(in asset: AVAsset) -> Data? {

        guard let assetReader = try? AVAssetReader(asset: asset) else {
            print("Unable to create AVAssetReader")
            return nil
        }

        guard let track = asset.tracks(withMediaType: AVMediaType.audio).first else {
            print("No audio track found in asset")
            return nil
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16
        ]

        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        assetReader.add(trackOutput)
        assetReader.startReading()

        let sampleData = NSMutableData()

        while assetReader.status == .reading {
            if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                if let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer) {
                    let length = CMBlockBufferGetDataLength(blockBufferRef)
                    let sampleBytes = UnsafeMutablePointer<Int16>.allocate(capacity: length)
                    CMBlockBufferCopyDataBytes(blockBufferRef, atOffset: 0, dataLength: length, destination: sampleBytes)
                    sampleData.append(sampleBytes, length: length)
                }
            }
        }

        if assetReader.status == .completed {
            return sampleData as Data
        } else {
            print("Failed to read audio samples from asset.")
            return nil
        }
    }
}

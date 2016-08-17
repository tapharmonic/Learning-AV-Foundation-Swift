//
//  MIT License
//
//  Copyright (c) 2016 Bob McCune http://bobmccune.com/
//  Copyright (c) 2016 TapHarmonic, LLC http://tapharmonic.com/
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

protocol PlayerControllerDelegate: class {
    func playbackStopped()
    func playbackBegan()
}

class PlayerController: NSObject, AVAudioPlayerDelegate {

    var playing = false
    weak var delegate: PlayerControllerDelegate?

    var players: [AVAudioPlayer]!

    override init() {
        super.init()

        let guitarPlayer = playerForFile("guitar")
        let bassPlayer = playerForFile("bass")
        let drumsPlayer = playerForFile("drums")

        guitarPlayer.delegate = self

        let nc = NotificationCenter.default

        nc.addObserver(self, selector: #selector(handleInterruption), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        nc.addObserver(self, selector: #selector(handleRouteChange), name: NSNotification.Name.AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())

        players = [guitarPlayer, bassPlayer, drumsPlayer]
    }

    func playerForFile(_ name: String) -> AVAudioPlayer {
        let fileURL = Bundle.main.url(forResource: name, withExtension: "caf")!
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.numberOfLoops = -1
            player.enableRate = true
            player.prepareToPlay()
            return player
        } catch let error as NSError {
            print("Error creating player: \(error.localizedDescription)")
            fatalError()
        }
    }

    func play() {
        if !playing {
            let delayTime = players.first!.deviceCurrentTime + 0.01
            for player in players {
                player.play(atTime: delayTime)
            }
            playing = true
        }
    }

    func stop() {
        if playing {
            for player in players {
                player.stop()
                player.currentTime = 0.0
            }
            playing = false
        }
    }

    func adjustRate(_ rate: Double) {
        for player in players {
            player.rate = Float(rate)
        }
    }

    func adjustPan(_ pan: Double, forPlayerAtIndex idx: Int) {
        if isValidIndex(idx) {
            players[idx].pan = Float(pan)
        }
    }

    func adjustVolume(_ volume: Double, forPlayerAtIndex idx: Int) {
        if isValidIndex(idx) {
            players[idx].volume = Float(volume)
        }
    }

    func isValidIndex(_ index: Int) -> Bool {
        return index >= 0 && index < players.count
    }

    func handleInterruption(_ notification: Notification) {
        if let info = (notification as NSNotification).userInfo {
            let type = info[AVAudioSessionInterruptionTypeKey] as! AVAudioSessionInterruptionType
            if type == .began {
                stop()
                delegate?.playbackStopped()
            } else {
                let options = info[AVAudioSessionInterruptionOptionKey] as! AVAudioSessionInterruptionOptions
                if options == .shouldResume {
                    play()
                    delegate?.playbackBegan()
                }
            }
        }
    }

    func handleRouteChange(_ notification: Notification) {
        if let info = (notification as NSNotification).userInfo {

            let reason = info[AVAudioSessionRouteChangeReasonKey] as! AVAudioSessionRouteChangeReason
            if reason == .oldDeviceUnavailable {
                let previousRoute = info[AVAudioSessionRouteChangePreviousRouteKey] as! AVAudioSessionRouteDescription
                let previousOutput = previousRoute.outputs.first!
                if previousOutput.portType == AVAudioSessionPortHeadphones {
                    stop()
                    delegate?.playbackStopped()
                }
            }
        }
    }
}

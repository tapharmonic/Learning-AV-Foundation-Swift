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

import UIKit

class MainViewController: UIViewController, PlayerControllerDelegate {

    @IBOutlet weak var playButton: PlayButton!
    @IBOutlet weak var rateKnob: GreenControlKnob!
    @IBOutlet weak var playLabel: UILabel!

    @IBOutlet var panKnobs: [ControlKnob]!
    @IBOutlet var volumeKnobs: [ControlKnob]!

    let controller = PlayerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        controller.delegate = self
    }

    @IBAction func play(_ sender: PlayButton) {
        if !controller.playing {
            controller.play()
            playLabel.text = NSLocalizedString("Stop", comment: "")
        } else {
            controller.stop()
            playLabel.text = NSLocalizedString("Play", comment: "")
        }

        // Toggle play button selected state
        playButton.isSelected = !playButton.isSelected
    }

    @IBAction func adjustVolume(_ sender: ControlKnob) {
        controller.adjustVolume(sender.value, forPlayerAtIndex: sender.tag)
    }

    @IBAction func adjustPan(_ sender: ControlKnob) {
        controller.adjustPan(sender.value, forPlayerAtIndex: sender.tag)
    }

    @IBAction func adjustRate(_ sender: ControlKnob) {
        controller.adjustRate(sender.value)
    }

    func playbackBegan() {
        playButton.isSelected = true
        playLabel.text = NSLocalizedString("Stop", comment: "")
    }

    func playbackStopped() {
        playButton.isSelected = false
        playLabel.text = NSLocalizedString("Play", comment: "")
    }
}

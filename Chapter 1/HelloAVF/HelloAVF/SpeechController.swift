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

import AVFoundation

class SpeechController {

    let synthesizer: AVSpeechSynthesizer
    private let voices: [AVSpeechSynthesisVoice]
    private let speechStrings: [String]

    init() {
        synthesizer = AVSpeechSynthesizer()

        voices = [
            AVSpeechSynthesisVoice(language: "en-US")!,
            AVSpeechSynthesisVoice(language: "en-GB")!
        ]

        speechStrings = [
            "Hello AV Foundation. How are you?",
            "I'm well! Thanks for asking.",
            "Are you excited about the book?",
            "Very! I have always felt so misunderstood.",
            "What's your favorite feature?",
            "Oh, they're all my babies.  I couldn't possibly choose.",
            "It was great to speak with you!",
            "The pleasure was all mine!  Have fun!"
        ]
    }

    func beginConversation() {
        for i in 0..<speechStrings.count {
            let utterance = AVSpeechUtterance(string: speechStrings[i])
            utterance.voice = voices[i % 2]
            utterance.rate = 0.5
            utterance.pitchMultiplier = 0.8
            utterance.postUtteranceDelay = 0.1
            synthesizer.speak(utterance)
        }
    }
}

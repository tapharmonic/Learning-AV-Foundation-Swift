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
import AVFoundation

class WaveformView: UIView {

    let widthScaling: CGFloat = 0.95
    let heightScaling: CGFloat = 0.85

    var asset: AVAsset? {
        didSet {
            guard let asset = asset else { return }
            SampleDataProvider.loadAudioSamples(in: asset) { sampleData in
                if let sampleData = sampleData {
                    self.filter = SampleDataFilter(sampleData: sampleData)
                    self.loadingView.stopAnimating()
                    self.setNeedsDisplay()
                }
            }
        }
    }

    var waveColor = UIColor.white {
        didSet {
            layer.borderWidth = 2.0
            layer.borderColor = waveColor.cgColor
            setNeedsDisplay()
        }
    }

    var filter: SampleDataFilter?
    var loadingView: UIActivityIndicatorView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func setupView() {
        backgroundColor = UIColor.clear
        layer.cornerRadius = 2.0
        layer.masksToBounds = true

        loadingView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        addSubview(loadingView)
        loadingView.startAnimating()
    }

    override func draw(_ rect: CGRect) {

        guard let context = UIGraphicsGetCurrentContext() else { return }

        guard let filteredSamples = filter?.filteredSamples(for: bounds.size) else {
            return
        }

        context.scaleBy(x: widthScaling, y: heightScaling)

        let xOffset = bounds.size.width - (bounds.size.width * widthScaling)
        let yOffset = bounds.size.height - (bounds.size.height * heightScaling)
        context.translateBy(x: xOffset / 2, y: yOffset / 2);

        let halfPath = CGMutablePath()
        halfPath.move(to: CGPoint(x: 0.0, y: rect.midY))

        for i in 0..<filteredSamples.count {
            let sample = CGFloat(filteredSamples[i])
            halfPath.addLine(to: CGPoint(x: CGFloat(i), y: rect.midY - sample))
        }

        halfPath.addLine(to: CGPoint(x: CGFloat(filteredSamples.count), y: rect.midY))

        let fullPath = CGMutablePath()
        fullPath.addPath(halfPath)

        var transform = CGAffineTransform.identity;
        transform = transform.translatedBy(x: 0, y: rect.height)
        transform = transform.scaledBy(x: 1.0, y: -1.0)
        fullPath.addPath(halfPath, transform: transform)

        context.addPath(fullPath)
        context.setFillColor(waveColor.cgColor)
        context.drawPath(using: .fill)
    }

    override func layoutSubviews() {
        let size = loadingView.frame.size
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0
        loadingView.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}


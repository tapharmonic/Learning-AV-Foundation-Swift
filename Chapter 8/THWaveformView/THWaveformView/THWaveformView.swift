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

import UIKit
import AVFoundation

class THWaveformView: UIView {

    let THWidthScaling: CGFloat = 0.95
    let THHeightScaling: CGFloat = 0.85

    var asset: AVAsset! {
        didSet {
            SampleDataProvider.loadAudioSamplesFromAsset(asset) {
                sampleData in
                if let sampleData = sampleData {
                    self.filter = SampleDataFilter(sampleData: sampleData)
                    self.loadingView.stopAnimating()
                    self.setNeedsDisplay()
                }
            }
        }
    }

    var waveColor = UIColor.whiteColor() {
        didSet {
            layer.borderWidth = 2.0
            layer.borderColor = waveColor.CGColor
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
        backgroundColor = UIColor.clearColor()
        layer.cornerRadius = 2.0
        layer.masksToBounds = true

        loadingView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        addSubview(loadingView)
        loadingView.startAnimating()
    }

    override func drawRect(rect: CGRect) {

        guard let filteredSamples = filter?.filteredSamplesForSize(bounds.size) else {
            return
        }

        let context = UIGraphicsGetCurrentContext();

        CGContextScaleCTM(context, THWidthScaling, THHeightScaling)

        let xOffset = bounds.size.width - (bounds.size.width * THWidthScaling)
        let yOffset = bounds.size.height - (bounds.size.height * THHeightScaling)
        CGContextTranslateCTM(context, xOffset / 2, yOffset / 2);

        let midY = CGRectGetMidY(rect)

        let halfPath = CGPathCreateMutable()
        CGPathMoveToPoint(halfPath, nil, 0.0, midY)

        for i in 0..<filteredSamples.count {
            let sample = CGFloat(filteredSamples[i])
            CGPathAddLineToPoint(halfPath, nil, CGFloat(i), midY - sample)
        }

        CGPathAddLineToPoint(halfPath, nil, CGFloat(filteredSamples.count), midY)

        let fullPath = CGPathCreateMutable()
        CGPathAddPath(fullPath, nil, halfPath)

        var transform = CGAffineTransformIdentity;
        transform = CGAffineTransformTranslate(transform, 0, CGRectGetHeight(rect))
        transform = CGAffineTransformScale(transform, 1.0, -1.0)
        CGPathAddPath(fullPath, &transform, halfPath)

        CGContextAddPath(context, fullPath)
        CGContextSetFillColorWithColor(context, waveColor.CGColor)
        CGContextDrawPath(context, .Fill)
    }

    override func layoutSubviews() {
        let size = loadingView.frame.size
        let x = (bounds.size.width - size.width) / 2.0
        let y = (bounds.size.height - size.height) / 2.0
        loadingView.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}


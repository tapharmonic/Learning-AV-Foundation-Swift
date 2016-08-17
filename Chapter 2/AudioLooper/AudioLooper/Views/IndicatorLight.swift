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

class IndicatorLight: UIView {

    var lightColor = UIColor.white {
        didSet {
            setNeedsDisplay()
        }
    }

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
        isUserInteractionEnabled = false
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext();

        let midX = rect.midX
        let minY = rect.minY
        let width = rect.width * 0.15
        let height = rect.height * 0.15
        let indicatorRect = CGRect(x: midX - (width / 2), y: minY + 15, width: width, height: height)

        let strokeColor = lightColor.darkerColor()
        context?.setStrokeColor(strokeColor.cgColor)
        context?.setFillColor(self.lightColor.cgColor)

        let shadowColor = lightColor.lighterColor()
        let shadowOffset = CGSize(width: 0.0, height: 0.0)
        let blurRadius = CGFloat(2.0)

        context?.setShadow(offset: shadowOffset, blur: blurRadius, color: shadowColor.cgColor)

        context?.addEllipse(in: indicatorRect)
        context?.drawPath(using: .fillStroke)
    }
}

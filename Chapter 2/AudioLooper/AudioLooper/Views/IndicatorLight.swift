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

class IndicatorLight: UIView {

    var lightColor = UIColor.whiteColor() {
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
        backgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext();

        let midX = CGRectGetMidX(rect)
        let minY = CGRectGetMinY(rect)
        let width = CGRectGetWidth(rect) * 0.15
        let height = CGRectGetHeight(rect) * 0.15
        let indicatorRect = CGRectMake(midX - (width / 2), minY + 15, width, height)

        let strokeColor = lightColor.darkerColor()
        CGContextSetStrokeColorWithColor(context, strokeColor.CGColor)
        CGContextSetFillColorWithColor(context, self.lightColor.CGColor)

        let shadowColor = lightColor.lighterColor()
        let shadowOffset = CGSizeMake(0.0, 0.0)
        let blurRadius = CGFloat(2.0)

        CGContextSetShadowWithColor(context, shadowOffset, blurRadius, shadowColor.CGColor)

        CGContextAddEllipseInRect(context, indicatorRect)
        CGContextDrawPath(context, .FillStroke)
    }
}

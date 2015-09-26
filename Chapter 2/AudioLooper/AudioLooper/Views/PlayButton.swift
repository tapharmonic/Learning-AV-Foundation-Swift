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

@IBDesignable
class PlayButton: UIButton {

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
        tintColor = UIColor.clearColor()
    }

    override func prepareForInterfaceBuilder() {
        setupView()
    }

    override var highlighted: Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let context = UIGraphicsGetCurrentContext();

        // Set up Colors
        let strokeColor = UIColor(white: 0.04, alpha: 1.0)
        var gradientLightColor = UIColor(red: 0.150, green: 0.150, blue: 0.150, alpha: 1.0)
        var gradientDarkColor = UIColor(red: 0.210, green: 0.210, blue: 0.210, alpha: 1.0)

        if highlighted {
            gradientLightColor = gradientLightColor.darkerColor().darkerColor()
            gradientDarkColor = gradientDarkColor.darkerColor().darkerColor()
        }

        let gradientColors = [gradientLightColor.CGColor, gradientDarkColor.CGColor]
        let locations = [CGFloat(0.0), CGFloat(1.0)]
        let gradient = CGGradientCreateWithColors(colorSpace, gradientColors, locations)

        var insetRect = CGRectInset(rect, 2.0, 2.0)

        // Draw Bezel
        CGContextSetFillColorWithColor(context, strokeColor.CGColor);
        let bezelPath = UIBezierPath(roundedRect: insetRect, cornerRadius: 6.0)
        CGContextAddPath(context, bezelPath.CGPath);
        CGContextSetShadowWithColor(context, CGSizeMake(0.0, 0.5), 2.0, UIColor.darkGrayColor().CGColor);
        CGContextDrawPath(context, .Fill);

        CGContextSaveGState(context);
        // Add Clipping Region for Knob Background
        insetRect = CGRectInset(insetRect, 3.0, 3.0);
        let buttonPath = UIBezierPath(roundedRect: insetRect, cornerRadius: 4.0)
        CGContextAddPath(context, buttonPath.CGPath);
        CGContextClip(context);

        let midX = CGRectGetMidX(insetRect);

        let startPoint = CGPointMake(midX, CGRectGetMaxY(insetRect));
        let endPoint = CGPointMake(midX, CGRectGetMinY(insetRect));

        // Draw Button Gradient Background
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions(rawValue: 0));

        // Restore graphis state
        CGContextRestoreGState(context);

        let fillColor = UIColor(white: 0.8, alpha: 1.0)
        CGContextSetFillColorWithColor(context, fillColor.CGColor);
        CGContextSetStrokeColorWithColor(context, fillColor.darkerColor().CGColor);

        let iconDim = CGFloat(24.0)
        // Draw Play Button
        if (!self.selected) {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, CGRectGetMidX(rect) - (iconDim - 3) / 2, CGRectGetMidY(rect) - iconDim / 2);
            CGContextMoveToPoint(context, 0.0, 0.0);
            CGContextAddLineToPoint(context, 0.0, iconDim);
            CGContextAddLineToPoint(context, iconDim, iconDim / 2);
            CGContextClosePath(context);
            CGContextDrawPath(context, .Fill);
            CGContextRestoreGState(context);
        }
            // Draw Stop Button
        else {
            CGContextSaveGState(context);
            let tx = (CGRectGetWidth(rect) - iconDim) / 2;
            let ty = (CGRectGetHeight(rect) - iconDim) / 2;
            CGContextTranslateCTM(context, tx, ty);
            let stopRect = CGRectMake(0.0, 0.0, iconDim, iconDim);
            let stopPath = UIBezierPath(roundedRect: stopRect, cornerRadius: 2.0)
            CGContextAddPath(context, stopPath.CGPath);
            CGContextDrawPath(context, .Fill);
            CGContextRestoreGState(context);
        }

    }
}

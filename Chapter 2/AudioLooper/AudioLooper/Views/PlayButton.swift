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
        backgroundColor = UIColor.clear
        tintColor = UIColor.clear
    }

    override func prepareForInterfaceBuilder() {
        setupView()
    }

    override var isHighlighted: Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {

        guard let context = UIGraphicsGetCurrentContext() else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB();

        // Set up Colors
        let strokeColor = UIColor(white: 0.04, alpha: 1.0)
        var gradientLightColor = UIColor(white: 0.150, alpha: 1.0)
        var gradientDarkColor = UIColor(white: 0.210, alpha: 1.0)

        if isHighlighted {
            gradientLightColor = gradientLightColor.darkerColor().darkerColor()
            gradientDarkColor = gradientDarkColor.darkerColor().darkerColor()
        }

        let gradientColors = [gradientLightColor.cgColor, gradientDarkColor.cgColor]
        let locations = [CGFloat(0.0), CGFloat(1.0)]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: locations)

        var insetRect = rect.insetBy(dx: 2.0, dy: 2.0)

        // Draw Bezel
        context.setFillColor(strokeColor.cgColor);
        let bezelPath = UIBezierPath(roundedRect: insetRect, cornerRadius: 6.0)
        context.addPath(bezelPath.cgPath);
        context.setShadow(offset: CGSize(width: 0.0, height: 0.5), blur: 2.0, color: UIColor.darkGray.cgColor);
        context.drawPath(using: .fill);

        context.saveGState();
        // Add Clipping Region for Knob Background
        insetRect = insetRect.insetBy(dx: 3.0, dy: 3.0);
        let buttonPath = UIBezierPath(roundedRect: insetRect, cornerRadius: 4.0)
        context.addPath(buttonPath.cgPath);
        context.clip();

        let midX = insetRect.midX;

        let startPoint = CGPoint(x: midX, y: insetRect.maxY);
        let endPoint = CGPoint(x: midX, y: insetRect.minY);

        // Draw Button Gradient Background
        context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0));

        // Restore graphis state
        context.restoreGState();

        let fillColor = UIColor(white: 0.8, alpha: 1.0)
        context.setFillColor(fillColor.cgColor);
        context.setStrokeColor(fillColor.darkerColor().cgColor);

        let iconDim = CGFloat(24.0)
        // Draw Play Button
        if (!self.isSelected) {
            context.saveGState();
            context.translateBy(x: rect.midX - (iconDim - 3) / 2, y: rect.midY - iconDim / 2);
            context.move(to: .zero)
            context.addLine(to: CGPoint(x: 0.0, y: iconDim))
            context.addLine(to: CGPoint(x: iconDim, y: iconDim / 2))
            context.closePath();
            context.drawPath(using: .fill);
            context.restoreGState();
        }
            // Draw Stop Button
        else {
            context.saveGState();
            let tx = (rect.width - iconDim) / 2;
            let ty = (rect.height - iconDim) / 2;
            context.translateBy(x: tx, y: ty);
            let stopRect = CGRect(x: 0.0, y: 0.0, width: iconDim, height: iconDim);
            let stopPath = UIBezierPath(roundedRect: stopRect, cornerRadius: 2.0)
            context.addPath(stopPath.cgPath);
            context.drawPath(using: .fill);
            context.restoreGState();
        }

    }
}

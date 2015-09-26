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
//  This component is based on Matthijs Hollemans' excellent MHRotaryKnob.
//  https://github.com/hollance/MHRotaryKnob
//
//  I have added some custom drawing and made some modifications to fit the
//  needs of this demo app.
//

import UIKit

@IBDesignable
class ControlKnob: UIControl {

    private let MAX_ANGLE = 120.0
    private let SCALING_FACTOR = 4.0

    private var _value = 0.0

    private var animated = true
    private var angle = 0.0
    private var indicatorView: IndicatorLight!
    private var touchOrigin = CGPointZero

    @IBInspectable var minimumValue:Double = -1.0
    @IBInspectable var maximumValue:Double = 1.0
    @IBInspectable var defaultValue:Double = 0.0
    @IBInspectable var value: Double {
        get {
            return _value
        }
        set {
            setValue(newValue, animated: false)
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
        self.backgroundColor = UIColor.clearColor()

        indicatorView = IndicatorLight(frame: bounds)
        indicatorView.lightColor = indicatorLightColor()
        addSubview(indicatorView)

        self.valueDidChangeFrom(defaultValue, toValue: defaultValue, animated: false)
    }

    func indicatorLightColor() -> UIColor {
        return UIColor.whiteColor()
    }

    func clampAngle(angle: Double) -> Double {
        if angle < -MAX_ANGLE {
            return -MAX_ANGLE
        } else if angle > MAX_ANGLE {
            return MAX_ANGLE
        }
        return angle
    }

    func angleForValue(value: Double) -> Double {
        return ((value - minimumValue) / (maximumValue - minimumValue) - 0.5) * (MAX_ANGLE * 2.0)
    }

    func valueForAngle(angle: Double) -> Double {
        return (angle / (MAX_ANGLE * 2.0) + 0.5) * (maximumValue - minimumValue) + minimumValue
    }

    func valueForPosition(point: CGPoint) -> Double {
        let delta = Double(touchOrigin.y - point.y)
        let newAngle = clampAngle(delta * SCALING_FACTOR + angle)
        let newValue = valueForAngle(newAngle)
        return newValue
    }

    func setValue(newValue: Double, animated: Bool) {
        let oldValue = self.value
        if newValue < minimumValue {
            _value = minimumValue
        } else if newValue > maximumValue {
            _value = maximumValue
        } else {
            _value = newValue
        }
        valueDidChangeFrom(oldValue, toValue: _value, animated: animated)
    }

    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let point = touch.locationInView(self)
        touchOrigin = point
        angle = angleForValue(self.value)
        highlighted = true
        setNeedsDisplay()
        return true
    }

    func handleTouch(touch: UITouch) -> Bool {
        if touch.tapCount > 1 {
            setValue(defaultValue, animated: true)
            return false
        }
        let point = touch.locationInView(self)
        self.value = valueForPosition(point)
        return true
    }

    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        if handleTouch(touch) {
            sendActionsForControlEvents(.ValueChanged)
        }
        return true
    }

    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        if let touch = touch {
            handleTouch(touch)
            sendActionsForControlEvents(.ValueChanged)
        }
        highlighted = false
        setNeedsDisplay()
    }

    override func prepareForInterfaceBuilder() {
        setNeedsDisplay()
        setupView()
    }

    override func drawRect(rect: CGRect) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = UIGraphicsGetCurrentContext()

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

        let insetRect = CGRectInset(rect, 0.5, 0.5)

        // Draw Bezel
        CGContextSetFillColorWithColor(context, strokeColor.CGColor)
        CGContextFillEllipseInRect(context, insetRect)

        let midX = CGRectGetMidX(insetRect)
        let midY = CGRectGetMidY(insetRect)

        // Draw Bezel Light Shadow Layer
        CGContextAddArc(context, midX, midY, CGRectGetWidth(insetRect) / 2, 0, CGFloat(M_PI * 2), 1)
        CGContextSetShadowWithColor(context, CGSizeMake(0.0, 0.5), 2.0, UIColor.darkGrayColor().CGColor)
        CGContextFillPath(context)

        // Add Clipping Region for Knob Background
        CGContextAddArc(context, midX, midY, (CGRectGetWidth(insetRect) - 6) / 2, 0, CGFloat(M_PI * 2), 1)
        CGContextClip(context)

        let startPoint = CGPointMake(midX, CGRectGetMaxY(insetRect))
        let endPoint = CGPointMake(midX, CGRectGetMinY(insetRect))
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions(rawValue: 0))
    }

    func valueDidChangeFrom(fromValue: Double, toValue: Double, animated: Bool) {

        let newAngle = angleForValue(toValue)

        if animated {
            let oldAngle = angleForValue(fromValue)
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            animation.duration = 0.2
            animation.values = [
                oldAngle * M_PI / 180.0,
                (newAngle + oldAngle) / 2.0 * M_PI / 180.0,
                newAngle * M_PI / 180.0
            ]
            animation.keyTimes = [0.0, 0.5, 1.0]
            animation.timingFunctions = [
                CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
                CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            ]
            indicatorView.layer.addAnimation(animation, forKey: nil)
        }

        indicatorView.transform = CGAffineTransformMakeRotation(CGFloat(newAngle * M_PI / 180.0))
    }
}

class GreenControlKnob: ControlKnob {
    override func indicatorLightColor() -> UIColor {
        return UIColor(red: 0.226, green: 1.0, blue: 0.226, alpha: 1.0)
    }
}

class OrangeControlKnob: ControlKnob {
    override func indicatorLightColor() -> UIColor {
        return UIColor(red: 1.0, green: 0.718, blue: 0.0, alpha: 1.0)
    }
}

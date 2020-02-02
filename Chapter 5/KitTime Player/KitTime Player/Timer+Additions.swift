//
//  MIT License
//
//  Copyright (c) 2014 Bob McCune http://bobmccune.com/
//  Copyright (c) 2014 TapHarmonic, LLC http://tapharmonic.com/
//  Copyright (c) 2020 Jan Weiß http://geheimwerk.de/
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

typealias TimerFireBlock = () -> Void

extension Timer {

	@objc class func executeTimerBlock(timer: Timer) {
		if let block = timer.userInfo as? TimerFireBlock {
			block()
		}
    }

	class func scheduledTimerWithTimeInterval(interval: TimeInterval, firing fireBlock: @escaping TimerFireBlock) -> AnyObject {
		return self.scheduledTimerWithTimeInterval(inTimeInterval: interval, repeating: false, firing: fireBlock)
    }

	class func scheduledTimerWithTimeInterval(inTimeInterval: TimeInterval, repeating: Bool, firing fireBlock: @escaping TimerFireBlock) -> AnyObject {
		return self.scheduledTimer(timeInterval: inTimeInterval, target: self, selector: #selector(Timer.executeTimerBlock), userInfo: fireBlock, repeats: repeating)
    }
	
}

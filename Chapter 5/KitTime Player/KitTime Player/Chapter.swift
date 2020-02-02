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
import AVFoundation

class Chapter {

    private(set) public var time: CMTime
    private(set) public var number: UInt
    private(set) public var title: String

	init(time:CMTime, number:UInt, title:String) {
		self.time = time
		self.number = number
		self.title = title
	}
	
	func isIn(_ timeRange: CMTimeRange) -> Bool {
		return (time > timeRange.start) &&
			(time < timeRange.duration)
	}

    func hasValidTime() -> Bool {
        return time.isValid
    }

    func debugDescription() -> String! {
        let format = "time:%@ number:%lu title:%@"
		let strTime = CMTimeCopyDescription(allocator: nil, time: time)! as String
        return String(format: format, strTime, number, title)
    }
}

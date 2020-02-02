//
//  LoadingView.swift
//  KitTime Player
//
//  Created by Jan on 02.02.20.
//  Copyright © 2020 Bob McCune. All rights reserved.
//

import AppKit

class LoadingView: NSView {

	override init(frame: NSRect) {
        super.init(frame: frame)
		self.setupView()
    }

	required init(coder: NSCoder) {
		super.init(coder: coder)!
		self.setupView()
    }

    func setupView() {
        let size: CGFloat = 40.0
        let x: CGFloat = (self.frame.size.width - size) / 2
        let y: CGFloat = (self.frame.size.height - size) / 2
        let rect: NSRect = NSMakeRect(x, y, size, size)
		
        let progressView: ITProgressIndicator! = ITProgressIndicator(frame: rect)
		progressView.color = NSColor.white
        progressView.lengthOfLine = 10.0
        progressView.numberOfLines = 12
        progressView.widthOfLine = 2.0
        progressView.animationDuration = 1.2
        progressView.innerMargin = 10.0
		
        self.addSubview(progressView)
    }

    func drawRect(dirtyRect: NSRect) {
		guard let context = NSGraphicsContext.current?.cgContext else {
			return
		}
		
		context.setFillColor(NSColor.black.cgColor)
		context.fill(dirtyRect)
    }
}

//
//  Window.swift
//  KitTime Player
//
//  Created by Jan on 02.02.20.
//  Copyright © 2020 Bob McCune. All rights reserved.
//

import AppKit

class Window: NSWindow {

    private var convertingView: NSView?

    func showConvertingView() {
		guard let contentView = self.contentView,
			let subview = contentView.subviews.first else {
			return
		}
		
		let loadingView = THLoadingView(frame: contentView.bounds)
		
        subview.addSubview(loadingView)
		self.convertingView = loadingView
    }

    func hideConvertingView() {
		guard let convertingView = self.convertingView else {
			return
		}
		
        convertingView.removeFromSuperview()
        self.convertingView = nil
    }
}

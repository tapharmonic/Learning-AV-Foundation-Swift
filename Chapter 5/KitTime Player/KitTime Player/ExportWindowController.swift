//
//  ExportWindowController.swift
//  KitTime Player
//
//  Created by Jan on 02.02.20.
//  Copyright © 2020 Bob McCune. All rights reserved.
//

import Cocoa
import AVFoundation

protocol ExportWindowControllerDelegate : AnyObject {
    func exportDidCancel()
}

class ExportWindowController: NSWindowController {
	
    public weak var exportSession: AVAssetExportSession? = nil {
		didSet {
			timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
				DispatchQueue.main.async(execute: {
					self?.progressIndicator?.doubleValue = Double(self?.exportSession?.progress ?? 0.0)
				})
			})
        }
    }
	
    public weak var delegate: ExportWindowControllerDelegate? = nil

    private var timer: Timer? = nil
	private var progress: CGFloat = 0.0
	
	@IBOutlet var progressIndicator: NSProgressIndicator? = nil
	
	override var windowNibName: String  {
		get {
			return "ExportWindow"
		}
	}

    deinit {
		if let timer = timer {
			timer.invalidate()
			self.timer = nil
		}
    }

    @IBAction func cancelExport(_ sender: AnyObject) {
    	if let delegate = delegate {
            delegate.exportDidCancel()
			
			if let timer = timer {
				timer.invalidate()
				self.timer = nil
			}
        }
    }
}

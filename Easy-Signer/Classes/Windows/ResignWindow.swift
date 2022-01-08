//
//  RootWindow.swift
//  Easy-Signer
//
//  Created by crazyball on 2021/11/14.
//

import Cocoa

class ResignWindow: BaseWindow {
    init() {
        super.init(contentRect:CGRect.zero, styleMask: [.miniaturizable, .closable, .titled], backing: .buffered, defer: false)
        title = "Easy Signer"
        contentViewController = ResignViewController()
    }
	
	deinit {

	}
}

//
//  AppDelegate.swift
//  Easy-Signer
//
//  Created by crazyball on 2021/11/14.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window = ResignWindow()
		window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

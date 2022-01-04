//
//  LoggerView.swift
//  Easy-Signer
//
//  Created by crazyball on 2021/12/26.
//

import AppKit

class LoggerView: NSScrollView {
    let logTextView = NSTextView()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        hasVerticalScroller = true
        hasHorizontalScroller = false
        
        documentView = logTextView
        logTextView.isEditable = false
        logTextView.isVerticallyResizable = true
        logTextView.isHorizontallyResizable = true
        logTextView.textContainerInset = CGSize(width: 5, height: 5)
        logTextView.minSize = logTextView.frame.size
        logTextView.maxSize = CGSize(width: Int.max, height: Int.max)
    }
}

extension LoggerView {
    func addLogString(_ log: String) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "[MM-dd HH:mm:ss] "
        let currentDateString = dateFormatter.string(from: Date())
        let out = currentDateString + log + "\n"

        DispatchQueue.main.async { [weak self] in
            self?.logTextView.string.append(out)
            self?.logTextView.scrollToEndOfDocument(nil)
        }
    }

    func clearLog() {
        DispatchQueue.main.async { [weak self] in
            self?.logTextView.string = ""
            self?.logTextView.scrollToBeginningOfDocument(nil)
        }
    }

}

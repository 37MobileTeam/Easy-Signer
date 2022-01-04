//
//  TaskCenter.swift
//  Easy-Signer
//
//  Created by crazyball on 2021/12/19.
//

import Foundation


struct TaskResult {
    var status: Int32
    var output: String
}

struct TaskError: LocalizedError {
    var code: Int32
    var output: String
    
    var errorDescription: String? {
        "\(code) \(output)"
    }
    

}

class TaskCenter {
    typealias TaskCompleteHandler = (TaskResult) -> Void
    
    /// 同步执行
    @discardableResult
    static func execute(lanuchPath: String, arguments: [String]? = nil, workingDirectory: URL? = nil) throws -> TaskResult {
        let task = Process()
        task.launchPath = lanuchPath
        task.arguments = arguments
        task.currentDirectoryURL = workingDirectory
        task.standardInput = FileHandle.nullDevice
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        pipe.fileHandleForReading.closeFile()
        
        if task.terminationStatus != 0 {
            throw TaskError(code: task.terminationStatus, output: String(data: data, encoding: .utf8) ?? "")
        }
        
        return TaskResult(status: task.terminationStatus, output: String(data: data, encoding: .utf8) ?? "")
    }
    
    /// 同步执行 Shell
    @discardableResult
    static func executeShell(command: String, workingDirectory: URL? = nil) throws -> TaskResult {
        return try execute(lanuchPath: "/bin/sh", arguments: ["-c", command], workingDirectory: workingDirectory)
    }
    
    /// 异步执行
    static func executeAsync(lanuchPath: String, arguments: [String]? = nil, workingDirectory: URL? = nil, completeHandler: TaskCompleteHandler?) {
        let originQueue = OperationQueue.current
        
        DispatchQueue.global().async {
            let task = Process()
            task.launchPath = lanuchPath
            task.arguments = arguments
            task.currentDirectoryURL = workingDirectory
            task.standardInput = FileHandle.nullDevice
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            
            var terminationObs: NSObjectProtocol?
            terminationObs = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: task, queue: OperationQueue.current, using: { notification in
                NotificationCenter.default.removeObserver(terminationObs!)
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                pipe.fileHandleForReading.closeFile()
                originQueue?.addOperation {
                    completeHandler?(TaskResult(status: task.terminationStatus, output:  String(data: data, encoding: .utf8) ?? ""))
                }
            })
            task.launch()
            task.waitUntilExit()
        }
    }
    
    /// 异步执行 Shell
    static func executeShellAsync(command: String, workingDirectory: URL? = nil, completeHandler: TaskCompleteHandler?) {
        return executeAsync(lanuchPath: "/bin/sh", arguments: ["-c", command], workingDirectory: workingDirectory, completeHandler: completeHandler)
    }
    
}

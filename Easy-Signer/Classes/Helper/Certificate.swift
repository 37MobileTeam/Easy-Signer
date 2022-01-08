//
//  Certificate.swift
//  Easy-Signer
//
//  Created by crazyball on 2022/1/8.
//

import Foundation

struct Certificate {
    var sha1: String
    var name: String
    
    /// 获取本地已安装的证书
    static func getCertificates() -> [Certificate] {
        if let result = try? TaskCenter.executeShell(command: "security find-identity -v -p codesigning"),
            let nameRe = try? NSRegularExpression(pattern: "\".+\"", options: .allowCommentsAndWhitespace),
            let sha1Re = try? NSRegularExpression(pattern: "[0-9A-z]{40}", options: .allowCommentsAndWhitespace) {
            return result.output.components(separatedBy: "\n").compactMap {
                guard let sha1Result = sha1Re.firstMatch(in: $0, range: NSRange(location: 0, length: $0.count)) else {
                    return nil
                }
                guard let nameResult = nameRe.firstMatch(in: $0, range: NSRange(location: 0, length: $0.count)) else {
                    return nil
                }
                let sha1 = NSString(string: $0).substring(with: sha1Result.range)
                let name = NSString(string: $0).substring(with: nameResult.range).replacingOccurrences(of: "\"", with: "")
                
                return Certificate(sha1: sha1, name: name)
            }
        }
        return []
    }
    
}

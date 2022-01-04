//
//  Profile.swift
//  Easy-Signer
//
//  Created by crazyball on 2021/12/20.
//

import Foundation

struct Profile {
    let name: String
    let uuid: String
    let teamId: String
    let createDate: Date
    let expirationDate: Date
    let applicationIdentifier: String
    
    static func getProfiles() -> [Profile] {
        let fileManager = FileManager()
        var profiles = [Profile]()
        guard let libraryDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return profiles
        }
        guard let profileURLs = try? fileManager.contentsOfDirectory(at: libraryDirectory.appendingPathComponent("MobileDevice/Provisioning Profiles"), includingPropertiesForKeys: nil, options: []) else {
            return profiles
        }
        for profileURL in profileURLs {
            if profileURL.pathExtension == "mobileprovision", let profile = Profile(profilePath: profileURL) {
                profiles.append(profile)
            }
        }
        profiles = profiles.sorted(by: {
            $0.createDate.timeIntervalSince1970 > $1.createDate.timeIntervalSince1970
        })
        return profiles
    }
    
    init?(profilePath: URL){
        guard let result = try? TaskCenter.executeShell(command: "security cms -D -i \"\(profilePath.path)\"") else {
            return nil
        }
        guard let data = try? PropertyListSerialization.propertyList(from: result.output.data(using: .utf8)!, options: .mutableContainers, format: nil) as? [String: Any] else {
            return nil
        }
        self.name = string(from: data["Name"])
        self.uuid = string(from: data["UUID"])
        self.teamId = (data["TeamIdentifier"] as? [String])?.first ?? ""
        self.createDate = data["CreationDate"] as! Date
        self.expirationDate = data["ExpirationDate"] as! Date
        
        let entitlements = data["Entitlements"] as? [String: Any] ?? [:]
        let fullApplicationIdentifier = entitlements["application-identifier"] as? String ?? ""
        if let periodIndex = fullApplicationIdentifier.firstIndex(of: ".") {
            self.applicationIdentifier = String(fullApplicationIdentifier[fullApplicationIdentifier.index(after: periodIndex)...])
        }else{
            self.applicationIdentifier = fullApplicationIdentifier
        }
        
    }
    
    
}


/// 进行类型转换获取字符串类型值
func string(from value: Any?, _ defaultValue: String = "") -> String {
    if let str = value as? String {
        return str
    } else if let int = value as? Int {
        return int.description
    } else if let double = value as? Double {
        return double.description
    } else if let float = value as? Float {
        return float.description
    } else {
        return defaultValue
    }
}

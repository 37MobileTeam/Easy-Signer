//
//  Resign.swift.swift
//  Easy-Signer
//
//  Created by crazyball on 2021/12/19.
//

import Foundation


class ResignManager {
    typealias ResignProgressHandler = (String) -> Void
    
    static func start(
        ipaPath: URL,
        certificate: String,
        profile: Profile,
        exportType: String,
        outputPath: URL,
        progressHandler: ResignProgressHandler? = nil
    ) throws {
        progressHandler?("\n******\n重签包体：\(ipaPath.path)\n******")
        
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .localDomainMask).first else {
            throw NSError(domain: "找不到 Caches 目录", code: -1, userInfo: nil)
        }
        
        /// 创建工作区
        let workspace = cacheDir.appendingPathComponent(Bundle.main.bundleIdentifier ?? "").appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true, attributes: nil)
        let ipaContent = workspace.appendingPathComponent("content")
        try FileManager.default.createDirectory(at: ipaContent, withIntermediateDirectories: true, attributes: nil)
        
        do {
            /// 1.  解压ipa
            progressHandler?("解压 ipa...")
            try unzipIPA(ipaPath: ipaPath, targetPath: ipaContent)

            /// 2.  删除包内无用内容
            progressHandler?("删除包内无用内容...")
            try removeUselessFile(directory: ipaContent)

            /// 3. 查找 app 文件
            let appPath = try findAppPath(directory: ipaContent.appendingPathComponent("Payload"))
            let appName = appPath.lastPathComponent
            progressHandler?("App 路径: \(appPath.path)")

            /// 读取 Info.plist
            let infoPlist = appPath.appendingPathComponent("Info.plist")
            guard let infoDict = NSDictionary(contentsOf: infoPlist) else {
                throw NSError(domain: "包内缺少 Info.plist", code: -1, userInfo: nil)
            }
            let appBundleId = infoDict["CFBundleIdentifier"] as? String ?? ""
            let appInVersion = infoDict["CFBundleVersion"] as? String ?? ""
            let appOutVersion = infoDict["CFBundleShortVersionString"] as? String ?? ""
            progressHandler?("\nInfo.plist 信息: \nBundle Id: \(appBundleId)\n内置版本: \(appInVersion)\n外置版本:\(appOutVersion)")
            
            /// 4. 读取 Appex
            let appexIds = try readAppexBundleIds(directory: appPath)
            progressHandler?("Appex列表: \(appexIds)")
            
            /// 5.  签名
            progressHandler?("开始重签名...")
            try codeSign(directory: ipaContent, certificateName: certificate)
            
            /// 复制 xcarchive 模板到工作区
            progressHandler?("复制 xcarchive 模板到工作区...")
            let templatePath = workspace.appendingPathComponent("template")
            try FileManager.default.copyItem(at: resignTemplate, to: templatePath)
            
            progressHandler?("修改 xcarchive 模板内容...")
            let xcarchivePath = templatePath.appendingPathComponent("payload.xcarchive")
            let xcarchiveInfoPlist = xcarchivePath.appendingPathComponent("Info.plist")
            let exportOptionsPlist = templatePath.appendingPathComponent("ExportOptions.plist")
            
            /// 复制 app 到 xcarchive 内
            try FileManager.default.copyItem(at: appPath, to: xcarchivePath.appendingPathComponent("Products/Applications/\(appName)"))
            
            /// 更新 xcarchive Info.plist
            updatePlist(url: xcarchiveInfoPlist) { info in
                info["Name"] = appName.components(separatedBy: ".").first!
                info["SchemeName"] = appName.components(separatedBy: ".").first!
                if var applicationProperties = info["ApplicationProperties"] as? [String: Any] {
                    applicationProperties["ApplicationPath"] = "Applications/\(appName)"
                    applicationProperties["CFBundleIdentifier"] = appBundleId
                    applicationProperties["CFBundleShortVersionString"] = appOutVersion
                    applicationProperties["CFBundleVersion"] = appInVersion
                    applicationProperties["SigningIdentity"] = certificate
                    applicationProperties["Team"] = profile.teamId
                    
                    info["ApplicationProperties"] = applicationProperties
                }
            }
            
            /// 更新 export options plist
            updatePlist(url: exportOptionsPlist) { info in
                info["signingCertificate"] = certificate.components(separatedBy: ":").first!
                info["method"] = exportType // app-store, ad-hoc, enterprise, development, validation 5种类型
                info["teamID"] = profile.teamId
                
                var provisioningProfiles = [String: String]()
                provisioningProfiles[appBundleId] = profile.name
                for appexId in appexIds {
                    provisioningProfiles[appexId] = profile.name
                }
                info["provisioningProfiles"] = provisioningProfiles
            }
            
            progressHandler?("开始导出 ipa...")
            let exportPath = workspace.appendingPathComponent("export")
            try xcodebuildExportArchive(xcarchivePath: xcarchivePath, exportPath: exportPath, exportOptionsPlist: exportOptionsPlist)
            progressHandler?("重签完成🎉🎉🎉")
            try moveIpa(exportPath: exportPath, outputPath: outputPath)
            try? FileManager.default.removeItem(at: workspace)
        } catch {
            print(error)
            try? FileManager.default.removeItem(at: workspace)
            throw error
        }
    }
    
    /// 获取本地已安装的证书
    static func getCertificates() -> [String] {
        if let result = try? TaskCenter.executeShell(command: "security find-identity -v -p codesigning"),
            let re = try? NSRegularExpression(pattern: "\".+\"", options: .allowCommentsAndWhitespace) {
            return result.output.components(separatedBy: "\n").map{
                if let result = re.firstMatch(in: $0, range: NSRange(location: 0, length: $0.count)) {
                    return NSString(string: $0).substring(with: result.range).replacingOccurrences(of: "\"", with: "")
                }
                return ""
            }.filter { !$0.isEmpty }
        }
        return []
    }
}


extension ResignManager {
    static var resignTemplate: URL {
        Bundle.main.resourceURL!.appendingPathComponent("Resources/resign_template")
    }
    
    /// 解压 ipa
    private static func unzipIPA(ipaPath: URL,targetPath: URL) throws {
        try TaskCenter.executeShell(command: "unzip \"\(ipaPath.path)\" -d \"\(targetPath.path)/\"")
    }
    
    /// 删除无用文件
    private static func removeUselessFile(directory: URL) throws {
        try TaskCenter.executeShell(command: "find -d \"\(directory.path)\" -name .DS_Store -o -name __MACOSX | xargs rm -rf")
    }
    
    /// 查找app
    private static func findAppPath(directory: URL) throws -> URL {
        let result = try TaskCenter.executeShell(command: "find -d \"\(directory.path)\" -maxdepth 1 -name  \"*.app\" | head -n 1")
        return URL(fileURLWithPath: result.output.trimmingCharacters(in: .newlines))
    }
    
    /// 处理 appex
    private static func readAppexBundleIds(directory: URL) throws -> [String] {
        let result = try TaskCenter.executeShell(command: "find -d \"\(directory.path)\" -name \"*.appex\"")
        var appexBundleIds = [String]()
        result.output.components(separatedBy: "\n").forEach { appexPath in
            let appexInfo = URL(fileURLWithPath: appexPath).appendingPathComponent("Info.plist")
            if let appexBundleId = NSMutableDictionary(contentsOf: appexInfo)?["CFBundleIdentifier"] as? String {
                appexBundleIds.append(appexBundleId)
            }
        }
        return appexBundleIds
    }
    
    /// 签名
    private static func codeSign(directory: URL, certificateName: String) throws {
        let result = try TaskCenter.executeShell(command: "find -d \"\(directory.path)\" -name *.app -o -name *.appex -o -name *.framework -o -name *.dylib")
        try result.output.split(separator: "\n").forEach { item in
            try TaskCenter.executeShell(command: "/usr/bin/codesign --continue -f -s \"\(certificateName)\" \"\(item)\"")
        }
    }
    
    private static func moveIpa(exportPath: URL, outputPath: URL) throws {
        try TaskCenter.executeShell(command: "find -d \"\(exportPath.path)\" -maxdepth 1 -name \"*.ipa\" | xargs -I {} mv -f {} \"\(outputPath.path)/\"")
    }
    
    private static func updateAppInfoPlist(appPath: URL) {
        
    }
    
    private static func updateXcarchiveInfoPlist() {
        
    }
    
    private static func xcodebuildExportArchive(xcarchivePath: URL, exportPath: URL, exportOptionsPlist: URL) throws {
        try TaskCenter.executeShell(command: "xcodebuild -exportArchive -archivePath \(xcarchivePath.path) -exportPath \(exportPath.path)  -exportOptionsPlist \(exportOptionsPlist.path)")
    }
}

extension ResignManager {
    static func updatePlist(url: URL, block: (NSMutableDictionary) -> Void) {
        if let info = NSMutableDictionary(contentsOf: url) {
            block(info)
            info.write(to: url, atomically: true)
        }
    }
}

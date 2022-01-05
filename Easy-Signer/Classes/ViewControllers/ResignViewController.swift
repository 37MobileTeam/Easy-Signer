//
//  RootViewController.swift
//  Easy-Signer
//
//  Created by crazyball on 2021/11/14.
//

import Cocoa
import SnapKit


class ResignViewController: BaseViewController {
    var certificates: [String] = []
    var profiles: [Profile] = []
    
    let ipaPathInput = NSTextField()
    let exportPathInput = NSTextField()
    let certPopBtn = NSPopUpButton()
    let profilePopBtn = NSPopUpButton()
    let exportTypePopBtn = NSPopUpButton()
    let loggerView = LoggerView()
    var timer: Timer?
    
    
	override func loadView() {
		view = NSView(frame: CGRect(x: 0, y: 0, width: 0, height: 450))
	}
	
	override func viewDidLoad() {
        certificates = ResignManager.getCertificates()
        profiles = Profile.getProfiles()
        
        let ipaTitle = NSTextField(labelWithString: "选择包体:")
        ipaTitle.isEditable = false
        ipaTitle.alignment = .right
        view.addSubview(ipaTitle)
        ipaTitle.snp.makeConstraints { make in
            make.width.equalTo(70)
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
        }
        
        ipaPathInput.placeholderString = "ipa或app路径"
        view.addSubview(ipaPathInput)
        ipaPathInput.snp.makeConstraints { make in
            make.centerY.equalTo(ipaTitle)
            make.left.equalTo(ipaTitle.snp.right).offset(15)
        }
        
        let ipaSelectBtn = NSButton(title: "选择", target: self, action: #selector(onTapSelectBtn))
        view.addSubview(ipaSelectBtn)
        ipaSelectBtn.snp.makeConstraints { make in
            make.centerY.equalTo(ipaTitle)
            make.right.equalToSuperview().offset(-20)
            make.left.equalTo(ipaPathInput.snp.right).offset(15)
        }
        
        let exportTitle = NSTextField(labelWithString: "导出目录:")
        exportTitle.isEditable = false
        exportTitle.alignment = .right
        view.addSubview(exportTitle)
        exportTitle.snp.makeConstraints { make in
            make.width.equalTo(70)
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(ipaTitle.snp.bottom).offset(20)
        }
        
        exportPathInput.placeholderString = "导出目录"
        view.addSubview(exportPathInput)
        exportPathInput.snp.makeConstraints { make in
            make.centerY.equalTo(exportTitle)
            make.left.equalTo(exportTitle.snp.right).offset(15)
        }
        
        let exportSelectBtn = NSButton(title: "选择", target: self, action: #selector(onTapSelectOutputBtn))
        view.addSubview(exportSelectBtn)
        exportSelectBtn.snp.makeConstraints { make in
            make.centerY.equalTo(exportTitle)
            make.right.equalToSuperview().offset(-20)
            make.left.equalTo(exportPathInput.snp.right).offset(15)
        }
        
        let certTitle = NSTextField(labelWithString: "签名证书:")
        certTitle.alignment = .right
        certTitle.isEditable = false
        view.addSubview(certTitle)
        certTitle.snp.makeConstraints { make in
            make.left.width.equalTo(ipaTitle)
            make.top.equalTo(exportTitle.snp.bottom).offset(20)
        }
        
        
        let certPopMenu = NSMenu()
        certificates.forEach { cert in
            certPopMenu.addItem(withTitle: cert, action: nil, keyEquivalent: "")
        }
        certPopBtn.menu = certPopMenu
        view.addSubview(certPopBtn)
        certPopBtn.snp.makeConstraints { make in
            make.centerY.equalTo(certTitle)
            make.left.equalTo(certTitle.snp.right).offset(15)
            make.right.equalToSuperview().offset(-20)
        }

        
        let profileTitle = NSTextField(labelWithString: "描述文件:")
        profileTitle.alignment = .right
        profileTitle.isEditable = false
        view.addSubview(profileTitle)
        profileTitle.snp.makeConstraints { make in
            make.left.width.equalTo(certTitle)
            make.top.equalTo(certTitle.snp.bottom).offset(20)
        }
        

        let profilePopMenu = NSMenu()
        profiles.forEach { profile in
            profilePopMenu.addItem(withTitle: "\(profile.name)(\(profile.applicationIdentifier))", action: nil, keyEquivalent: "")
        }
        profilePopBtn.menu = profilePopMenu
        view.addSubview(profilePopBtn)
        profilePopBtn.snp.makeConstraints { make in
            make.centerY.equalTo(profileTitle)
            make.left.right.equalTo(certPopBtn)
        }
        
        let exportTypeTitle = NSTextField(labelWithString: "导出类型:")
        exportTypeTitle.alignment = .right
        exportTypeTitle.isEditable = false
        view.addSubview(exportTypeTitle)
        exportTypeTitle.snp.makeConstraints { make in
            make.left.width.equalTo(profileTitle)
            make.top.equalTo(profileTitle.snp.bottom).offset(20)
        }
        

        let exportTypePopMenu = NSMenu()
        ExportType.allCases.forEach { type in
            exportTypePopMenu.addItem(withTitle: type.rawValue, action: nil, keyEquivalent: "")
        }
        exportTypePopBtn.menu = exportTypePopMenu
        view.addSubview(exportTypePopBtn)
        exportTypePopBtn.snp.makeConstraints { make in
            make.centerY.equalTo(exportTypeTitle)
            make.left.right.equalTo(certPopBtn)
        }
        
        let logTitle = NSTextField(labelWithString: "日志输出:")
        logTitle.isEnabled = false
        view.addSubview(logTitle)
        logTitle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(exportTypePopBtn.snp.bottom).offset(20)
        }

        view.addSubview(loggerView)
        loggerView.snp.makeConstraints { make in
            make.top.equalTo(logTitle.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        
        let startBtn = NSButton(title: "开始", target: self, action: #selector(onTapStart))
        view.addSubview(startBtn)
        startBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
            make.top.equalTo(loggerView.snp.bottom).offset(10)
        }
    }
    
}


extension ResignViewController {
    @objc func onTapSelectBtn() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        let result = panel.runModal()
        if result == .OK, let selectedUrl = panel.url {
            ipaPathInput.stringValue = selectedUrl.path
        }
    }
    
    @objc func onTapSelectOutputBtn() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        let result = panel.runModal()
        if result == .OK, let selectedUrl = panel.url {
            exportPathInput.stringValue = selectedUrl.path
        }
    }
    
    @objc func onTapStart() {
        loggerView.clearLog()
        let cert = certificates[certPopBtn.indexOfSelectedItem]
        let profile = profiles[profilePopBtn.indexOfSelectedItem]
        let exportType = exportTypePopBtn.selectedItem?.title ?? ExportType.development.rawValue
        
        let ipaPath = URL(fileURLWithPath: ipaPathInput.stringValue)
        let outputPath = URL(fileURLWithPath: exportPathInput.stringValue)
		guard ipaPath.pathExtension == "ipa" || ipaPath.pathExtension == "app" else {
            HUD.alert("只支持重签ipa和app文件")
            return
        }
        HUD.showLoading(view)
        DispatchQueue.global().async {
            do {
                try ResignManager.start(ipaPath:ipaPath, certificate: cert, profile: profile,exportType: exportType, outputPath: outputPath ,progressHandler: { text in
                    self.loggerView.addLogString(text)
                })
            } catch {
                self.loggerView.addLogString("**重签名失败❌**\n\(error.localizedDescription)")
                HUD.alert(error.localizedDescription)
            }
            DispatchQueue.main.async {
                HUD.dismissLoading()
            }
        }
    }
}


enum ExportType: String, CaseIterable {
    case development = "development"
    case appStore = "app-store"
    case adHoc = "ad-hoc"
    case enterprise = "enterprise"
    case validation = "validation"
}

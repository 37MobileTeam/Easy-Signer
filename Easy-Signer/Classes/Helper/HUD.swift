//
//  HUD.swift
//  Easy-Signer
//
//  Created by crazyball on 2022/1/2.
//

import Foundation

enum HUD {
    static private var loadingHud: MBProgressHUD?
    
    static func showLoading(_ view: NSView){
        if let hud = loadingHud {
            hud.hide(true)
        }
        loadingHud = MBProgressHUD(view: view)
        view.addSubview(loadingHud!)
        loadingHud?.show(true)
    }
    
    static func dismissLoading(){
        loadingHud?.hide(true)
    }
    
    static func alert(_ content:String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "温馨提示"
            alert.informativeText = content
            alert.runModal()
        }
    }

}

//
//  PPWebDAVConfigViewController.swift
//  PandaNote
//
//  Created by panwei on 2019/8/29.
//  Copyright © 2019 WeirdPan. All rights reserved.
//

import UIKit

class PPWebDAVConfigViewController: PPBaseViewController {

    let table = XDFastTableView()
    var cloudType = ""
    var serverURL = ""
    var userName = ""
    var password = ""
    var remark = ""
    var extraString = "" //额外的字段
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "新增服务器设置"
        self.view.backgroundColor = UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.00)
        let leftNames = ["服务器","账号","密码","备注"]
        let placeHolders = ["服务器地址","账号（Dropbox不需要）","密码或token","备注（显示用）"]
        let texts = [serverURL,userName,password,remark]
        
        
        
        self.view.addSubview(table)
        table.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).offset(88)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        table.registerCellClass(PPTextFieldTableViewCell.self)
//        table.dataSource = ["服务器地址","账号","密码","备注"]
        for i in 0..<leftNames.count {
            let model = PPAddCloudServiceModel()
            model.leftName = leftNames[i]
            model.placeHolder = placeHolders[i]
            model.textValue = texts[i]
            if (self.cloudType == "Dropbox") && (model.leftName == "服务器" || model.leftName == "账号"){
                model.textFieldNonnull = false
            }
            if (self.cloudType == "baiduyun") && (model.leftName == "服务器" || model.leftName == "账号"){
                model.textFieldNonnull = false
            }
            table.dataSource.append(model)
        }
        table.didSelectRowAtIndexHandler = {(index: Int) ->Void in
            print("click==\(index)")
        }
        
        
        
        
        let saveBtn = UIButton.init()
        self.view.addSubview(saveBtn)
        saveBtn.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).offset(-88)
            make.centerX.equalTo(self.view)
            make.height.equalTo(50)
            make.width.equalTo(150)
        }
        saveBtn.setTitle("保存", for: UIControl.State.normal)
        saveBtn.backgroundColor = UIColor(red:0.13, green:0.75, blue:0.39, alpha:1.00)
        saveBtn.addTarget(self, action: #selector(submit), for: UIControl.Event.touchUpInside)
        
        
        let tipsLB = UILabel()
        self.view.addSubview(tipsLB)
        tipsLB.snp.makeConstraints { (make) in
            make.bottom.equalTo(saveBtn.snp.top).offset(-44)
            make.left.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }
        tipsLB.numberOfLines = 0
        tipsLB.textColor = UIColor(hexRGBValue: 0xcd594b)
        tipsLB.text = """
        注意：
        Dropbox、百度网盘的服务器和账号可不填写
        """
    }
    
    @objc func submit() -> Void {
        print("submit!请忽略下面的垃圾代码")
        let cell1:PPTextFieldTableViewCell = table.tableView.cellForRow(at: IndexPath.init(row: 0, section: 0)) as! PPTextFieldTableViewCell
        let cell2:PPTextFieldTableViewCell = table.tableView.cellForRow(at: IndexPath.init(row: 1, section: 0)) as! PPTextFieldTableViewCell
        let cell3:PPTextFieldTableViewCell = table.tableView.cellForRow(at: IndexPath.init(row: 2, section: 0)) as! PPTextFieldTableViewCell
        let cell4:PPTextFieldTableViewCell = table.tableView.cellForRow(at: IndexPath.init(row: 3, section: 0)) as! PPTextFieldTableViewCell

        if cell1.textFieldNonnull && cell1.serverNameTF.text!.length < 1 {
            PPHUD.showHUDFromTop("请填写服务器地址", isError: true)
            return
        }
        if cell2.textFieldNonnull && cell2.serverNameTF.text!.length < 1 {
            PPHUD.showHUDFromTop("请填写账号", isError: true)
            return
        }
        if cell3.textFieldNonnull && cell3.serverNameTF.text!.length < 1 {
            PPHUD.showHUDFromTop("请填写密码", isError: true)
            return
        }
        if cell4.textFieldNonnull && cell4.serverNameTF.text!.length < 1 {
            PPHUD.showHUDFromTop("请填写备注", isError: true)
            return
        }
        var serverList = PPUserInfo.shared.pp_serverInfoList
            let newServer = ["PPWebDAVServerURL":cell1.serverNameTF.text!,
            "PPWebDAVUserName":cell2.serverNameTF.text!,
            "PPWebDAVPassword":cell3.serverNameTF.text!,
            "PPCloudServiceType":self.cloudType,
            "PPCloudServiceExtra":self.extraString,
            "PPWebDAVRemark":cell4.serverNameTF.text!]
            serverList.append(newServer)
            PPUserInfo.shared.pp_serverInfoList = serverList
        
        
        PPHUD.showHUDFromTop("设置成功")
        PPUserInfo.shared.initConfig()
        //新添加的配置设为当前服务器配置（选中最后一个）
        PPUserInfo.shared.pp_lastSeverInfoIndex = PPUserInfo.shared.pp_serverInfoList.count - 1
        PPUserInfo.shared.pp_Setting["pp_lastSeverInfoIndex"] = PPUserInfo.shared.pp_lastSeverInfoIndex
        PPFileManager.shared.initCloudServiceSetting()
        if let home = self.navigationController?.viewControllers[0] {
            let vc = home as! PPFileListViewController
            vc.setNavTitle(cell4.serverNameTF.text,true)
        }
        PPUserInfo.shared.refreshFileList = true
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    

}

//
//  PPUserInfoManager.swift
//  PandaNote
//
//  Created by Panway on 2019/8/28.
//  Copyright © 2019 Panway. All rights reserved.
//  App公有设置和用户私有设置混在一起，后期优化

import Foundation



class PPUserInfo: NSObject {
    public enum PPCloudServiceType : String {
        case webdav = "webdav"
        case local = "local"
        case dropbox = "Dropbox"
        case baiduyun = "baiduyun"
        case onedrive = "OneDrive"
    }
    static let shared = PPUserInfo()

    var webDAVServerURL = ""
    var webDAVUserName:String?
    var webDAVPassword:String?
    var webDAVRemark = ""
    var cloudServiceExtra = ""//额外的字段
    /// 坚果云、Drpbox等
    var cloudServiceType:PPCloudServiceType = .webdav
    /// 沙盒Sandbox/Library/PandaCache
    var pp_mainDirectory:String!
    var pp_mainDirectoryURL:URL!
    var pp_fileIcon = [String:String]()
    /// 本地时间相对于格林尼治时间的差距
    var pp_timezoneOffset:Int!
    var pp_JSONConfig:String!
    /// webview资源
    var pp_WebViewResource = [String]()
    /// 当前选择的是哪个服务器
    var pp_lastSeverInfoIndex = 0
    /// App配置备份到服务器的位置
    var appSettingLocationInServer = ""
    /// 强制刷新文件列表的时候设为true（添加完服务器配置）
    var refreshFileList = false

    /// 最近访问文件列表
     var pp_RecentFiles:Array<PPFileObject> = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(pp_RecentFiles)
                try? encodedData.write(to: URL(fileURLWithPath: self.pp_mainDirectory + "/PP_RecentFiles.json"))
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    
    /// App等跟哟用户隐私无关的设置
    public var pp_Setting : Dictionary<String, Any> = [:] {
        didSet {
            debugPrint("旧值：\(String(describing: oldValue)) \n新值： \(String(describing: pp_Setting))")
//            let data:NSData = NSKeyedArchiver.archivedData(withRootObject: pp_Setting) as NSData
//            data.write(toFile: self.pp_mainDirectory+"/PP_UserPreference", atomically: true)
            if let jsonData = try? JSONSerialization.data(withJSONObject: pp_Setting, options: JSONSerialization.WritingOptions.prettyPrinted) {
                do {
                    try jsonData.write(to: URL(fileURLWithPath: self.pp_mainDirectory + "/PP_JSONConfig.json"), options: .atomic)
                } catch {
                    debugPrint(error)
                }
                                
            }
//            if oldValue != pp_Setting {
                //save to disk
                
//            }
        }
    }
    /// 服务器信息（坚果云、Dropbox等）
    var pp_serverInfoList : [[String : String]] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(pp_serverInfoList)
                try? encodedData.write(to: URL(fileURLWithPath: self.pp_mainDirectory + "/PP_CloudServerSetting.json"))
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func initConfig() -> Void {
        self.pp_mainDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]//documentDirectory
        self.pp_mainDirectory += "/PandaNote"
        self.pp_mainDirectoryURL = URL.init(fileURLWithPath: self.pp_mainDirectory)
        pp_fileIcon = ["pdf":"ico_pdf",
                       "mp3":"ico_music",
                       "zip":"ico_zip",
                       "md":"ico_txt",
                       "txt":"ico_txt",
                       "html":"ico_code",
                       "css":"ico_code",
                       "js":"ico_code",
                       "py":"ico_code",
                       "json":"ico_code",
                       "MP4":"ico_video",
                       "mp4":"ico_video",
                       "mov":"ico_video",
                       "pdf2":"ico_pdf"]
        do {
            if !FileManager.default.fileExists(atPath: self.pp_mainDirectory) {
                try FileManager.default.createDirectory(atPath: self.pp_mainDirectory, withIntermediateDirectories: true, attributes: nil)
            }
        }
        catch {}
        self.pp_timezoneOffset = TimeZone.current.secondsFromGMT()
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: self.pp_mainDirectory+"/PP_JSONConfig.json")) {
//            let dict2 = NSKeyedUnarchiver.unarchiveObject(with: data)
//            self.pp_Setting = dict2 as! Dictionary<String, Any>
            if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                self.pp_Setting = json as! Dictionary<String, Any>
            }
            if let currentServerIndex = PPUserInfo.shared.pp_Setting["pp_lastSeverInfoIndex"] {
                self.pp_lastSeverInfoIndex = currentServerIndex as! Int
            }
        }
        
        //服务器配置
        if let data = try? Data(contentsOf: URL(fileURLWithPath: self.pp_mainDirectory+"/PP_CloudServerSetting.json")) {
            if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                self.pp_serverInfoList = json as! [[String : String]]
            }
        }
        else {
            debugPrint("no server config found 初次安装无数据，默认使用本地文件列表")
            let newServer = ["PPWebDAVUserName":"本地",
                             "PPWebDAVRemark":"本地",
                             "PPCloudServiceType":PPCloudServiceType.local.rawValue]
            self.pp_serverInfoList = [newServer]
        }
        
        
        if let recentFileData = try? Data(contentsOf: URL(fileURLWithPath: self.pp_mainDirectory+"/PP_RecentFiles.json")) {
            let archieveArray = try? JSONDecoder().decode([PPFileObject].self, from: recentFileData)
            self.pp_RecentFiles = archieveArray ?? []
        }
        
    }
    //MARK:最近文件
    func removeFileInRecentFiles(_ fileObj:PPFileObject) {
        if let index = pp_RecentFiles.firstIndex(of: fileObj) {
            pp_RecentFiles.remove(at: index)
        }
    }
    /// 插入最近浏览的文件或目录到最近浏览列表（如果有需要的话）
    func insertToRecentFiles(_ fileObj:PPFileObject) {
        removeFileInRecentFiles(fileObj)
        pp_RecentFiles.insert(fileObj, at: 0)
        if pp_RecentFiles.count > 30 {
            pp_RecentFiles.removeLast()
        }
    }
    //MARK:更新云盘服务设置
    func updateCurrentServerInfo(index:Int) {
        let webDAVInfoArray = PPUserInfo.shared.pp_serverInfoList
        if webDAVInfoArray.count < 1 {
            return
        }
        let webDAVInfo = webDAVInfoArray[index]

        PPUserInfo.shared.webDAVServerURL = webDAVInfo["PPWebDAVServerURL"] ?? ""
        PPUserInfo.shared.webDAVUserName = webDAVInfo["PPWebDAVUserName"] ?? ""
        PPUserInfo.shared.webDAVPassword = webDAVInfo["PPWebDAVPassword"] ?? ""
        PPUserInfo.shared.webDAVRemark = webDAVInfo["PPWebDAVRemark"] ?? ""
        PPUserInfo.shared.cloudServiceExtra = webDAVInfo["PPCloudServiceExtra"] ?? ""
        PPUserInfo.shared.cloudServiceType = PPCloudServiceType(rawValue: webDAVInfo["PPCloudServiceType"] ?? "") ?? .webdav
    }
    class func pp_valueForSettingDict(key : String) -> Bool {
        return self.pp_boolValue(key)
    }
    class func pp_boolValue(_ keyInSettingDict : String) -> Bool {
        if let string : String = PPUserInfo.shared.pp_Setting[keyInSettingDict] as? String {
            return string.bool
        }
        return false
    }
    class func saveObject(_ objcet:Any) {
        
    }
    ///共享的网页，提高网页显示速度
    lazy var webViewController: PPWebViewController = {
        let webVC = PPWebViewController()
//        webVC.urlString = "https://tophub.today"
        return webVC
    }()
//    func save(_ value: String, forKey defaultName: String) -> Void {
//        UserDefaults.standard.setValue(value, forKey: defaultName)
//
//    }
    
}

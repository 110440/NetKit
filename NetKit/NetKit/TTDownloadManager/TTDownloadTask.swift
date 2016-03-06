//
//  TTDownloadTask.swift
//  testTableView
//
//  Created by tanson on 16/3/2.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

//MARK:- TaskState
public enum TTDownloadTaskState : Int {
    case Running
    case Suspended
    case Failed
    case Completed
}

//MARK:- DownloadTask
public class TTDownloadTask {
    
    public var url:NSURL
    private let directoryName:String
    
    public internal(set) var state:TTDownloadTaskState = .Suspended
    
    public internal(set) var resumeSize:Int64 = 0
    public var fileSize:Int64 = 0 //(正在获取文件大小,或服务器不提供文件大小信息)
    public var StringForFileSize:String {
        return TTGetFileSizeStr(self.fileSize)
    }
    
    internal var totalBytesWritten:Int64 = 0
    internal var totalBytesExpectedToWrite:Int64 = 0
    
    public var stringForFileSizeWritten:String{
        return TTGetFileSizeStr( self.totalBytesWritten + self.resumeSize )
    }
    
    // 0 ~ 100
    public var progress:Int {
        if self.finished { return 100 }
        if self.fileSize <= 0 { return 0 }
        return Int(Float(self.totalBytesWritten + self.resumeSize ) / Float(self.fileSize) * 100)
    }
    
    internal var session:NSURLSession?
    internal var task:NSURLSessionDownloadTask?
    
    internal var resumeData:NSData? {
        
        get{
            return NSData(contentsOfFile: self.fileCachePath)
        }
        set{
            
            if !NSFileManager.defaultManager().fileExistsAtPath(self.fileCachePath){
                NSFileManager.defaultManager().createFileAtPath(self.fileCachePath, contents: nil, attributes: nil)
            }
            
            let cacheFileHandle = NSFileHandle(forWritingAtPath: self.fileCachePath)
            cacheFileHandle?.seekToEndOfFile()
            cacheFileHandle?.writeData(newValue ?? NSData() )
            cacheFileHandle?.synchronizeFile()
            cacheFileHandle?.closeFile()
        }
    }
    
    private var userInfoData = [String:AnyObject]()
    public func setUserInfoData(data:AnyObject,forKey:String){
        self.userInfoData[forKey] = data
    }
    public func getUserInfoData(key:String)->AnyObject?{
        return self.userInfoData[key]
    }
    
    // 只能由 DownloadManager 创建 task , 检查 url 合法性
    internal init(urlStr:String,dir:String){
        self.url = NSURL(string: urlStr)!
        self.directoryName = dir
    }
    
    internal var _finished:Bool?
    public var finished:Bool {
        get{
            if self._finished == nil {
                self._finished = NSFileManager.defaultManager().fileExistsAtPath(self.filePath)
            }
            return self._finished!
        }
    }
    
    public var fileName:String{
        
        var name = self.url.absoluteString.stringByRemovingPercentEncoding
        if name == nil{
            let str = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(nil, (self.url.absoluteString as CFString) ,("" as CFString), UInt32( CFStringEncodings.GB_18030_2000.rawValue))
            name = str as String
        }
        if name == nil || name?.characters.count <= 0 { return "未知文件名" }
        return (name! as NSString).lastPathComponent
    }
    
    public var filePath:String{
        return (TTGetDownloadPath(self.directoryName) as NSString).stringByAppendingPathComponent(self.fileName)
    }
    
    private var fileCachePath:String{
        return (TTGetDownloadPath(self.directoryName) as NSString).stringByAppendingPathComponent(self.fileName + ".temp" )
    }
    

    public func resume(){
        
        if self.finished { return }
        
        switch self.state{
        case .Completed,.Running: return
        default: break
        }
        
        let request = NSMutableURLRequest(URL: self.url)
        if let resumeData = self.resumeData {
            
            let startPos = Int64( resumeData.length )
            let rangeHeadStr = "bytes=\(startPos)-"
            request.setValue(rangeHeadStr, forHTTPHeaderField: "Range")
            self.resumeSize = startPos
        }
        self.task = self.session!.downloadTaskWithRequest(request)
        self.task!.resume()
        self.state = .Running
    }
    
    public func suspend(){
        
        if self.finished { return }
        
        switch self.state{
        case .Completed,.Failed,.Suspended: return
        default: break
        }
        
        guard let task =  self.task else {return}
        task.cancelByProducingResumeData { (resumeData) -> Void in }
        //self.state = .Failed // error handle 设置
    }
    
    func deleteLocalFile(){
        if self.state == .Running {
            self.task!.cancel()
        }
        let filePath = self.filePath
        if NSFileManager.defaultManager().fileExistsAtPath(filePath){
            try! NSFileManager.defaultManager().removeItemAtPath(filePath)
        }
    }
    func deleteCachefile(){
        let filePath = self.fileCachePath
        if NSFileManager.defaultManager().fileExistsAtPath(filePath){
            try! NSFileManager.defaultManager().removeItemAtPath(filePath)
        }
    }
    
}

//MARK: 序列化
extension TTDownloadTask{
    
    func toDictionary()->NSDictionary{
        let dic = NSMutableDictionary()
        dic["url"] = self.url.absoluteString
        dic["dir"] = self.directoryName
        dic["fileSize"] = NSNumber(longLong: self.fileSize ?? 0)
        dic["state"] = NSNumber(long: self.state.rawValue )
        return dic
    }
    
    class func taskFromDictionary(dicData:NSDictionary)-> TTDownloadTask {
        
        let url = dicData["url"] as! String
        let dir = dicData["dir"] as! String
        let fileSize = (dicData["fileSize"] as! NSNumber).longLongValue
        var state = TTDownloadTaskState(rawValue: ( dicData["state"] as! NSNumber ).longValue )
        let task = TTDownloadTask(urlStr: url, dir: dir)
        task.fileSize = fileSize
        
        if state == .Running{
            //如果任务在后台执行时失败，状态可能保持.Running
            state = .Failed
        }
        task.state = state!
        
        if let data = task.resumeData {
            task.resumeSize = Int64(data.length)
        }else if task.finished {
            task.resumeSize = fileSize
        }
        return task
    }
}

//
//private extension TTDownloadTask{
//    
//    func requestForTotalBytesForURL(url: NSURL, callback: (totalBytes:Int64) -> ()) {
//        let headRequest = NSMutableURLRequest(URL: url)
//        headRequest.setValue("", forHTTPHeaderField: "Accept-Encoding")
//        headRequest.HTTPMethod = "HEAD"
//        headRequest.timeoutInterval = 10.0
//        let sharedSession = NSURLSession.sharedSession()
//        let headTask = sharedSession.dataTaskWithRequest(headRequest) { (data, response, error) -> Void in
//            if let e = error {
//                print("TTDownloadManager get file head failed e:\(e)")
//                return
//            }
//            if let expectedContentLength = response?.expectedContentLength {
//                callback(totalBytes: expectedContentLength)
//            } else {
//                print(" TTDownloadManager : 服务器不提供文件长度信息!")
//                callback(totalBytes: -1)
//            }
//        }
//        headTask.resume()
//    }
//}
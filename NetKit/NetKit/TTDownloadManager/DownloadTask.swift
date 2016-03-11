//
//  DownloadTask.swift
//  DownLoader
//
//  Created by tanson on 16/3/8.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

public enum DownloadTaskState:String{
    case downloading
    case paused
    case failed
}

public class DownloadTask {
    
    public      var urlStr:String
    public      var recvedSize:Int64 = 0
    internal    var rawTask:NSURLSessionDownloadTask?
    public      var state:DownloadTaskState = .paused
    public      var fileSize:Int64 = 0
    internal    var startTime:NSDate? = NSDate()
    
    // 每次resume开始时，已经接收到的数据大小，不包括缓存
    internal    var coldSize:Int64 = 0
    
    public      var speed:Int64 = 0
    internal    var offset:Int64 = 0
    
    internal init(urlStr:String){
        self.urlStr = urlStr
    }
    
    public var progress:Float {
        if self.fileSize <= 0 { return 0}
        return Float(self.recvedSize) / Float(self.fileSize)
    }
    
    public var fileName:String {
        let name = (self.urlStr as NSString).lastPathComponent
        return DownloadUtil.removPercentForUrlStr(name)
    }
    internal var tempFileName:String{
        return self.fileName + ".temp"
    }
    
    internal func resume(){
        self.state = .downloading
        self.rawTask!.resume()
        self.startTime = NSDate()
    }
    
    internal func pause() {
        self.state = .paused
        self.rawTask!.suspend()
        self.coldSize = self.recvedSize - self.offset
        self.speed = 0
    }
    
    internal func cancell(){self.state = .failed ; self.rawTask!.cancel();self.rawTask = nil }
    internal func pauseOrResume(){
        switch self.state {
        case .downloading:
            self.pause()
        case .paused:
            self.resume()
        default:
            self.resume()
        }
    }
    
    //MARK:serialization 
    internal func toDictionary()->NSMutableDictionary{
        let dic = NSMutableDictionary()
        dic["urlStr"] = self.urlStr
        dic["recvedSize"] = NSNumber(longLong: self.recvedSize)
        dic["state"] = self.state.rawValue
        dic["fileSize"] = NSNumber(longLong: self.fileSize)
        return dic
    }
    
    internal static func fromDictionary(dic:NSDictionary)->DownloadTask{
        let urlStr = dic["urlStr"] as! String
        let recvedSize = dic["recvedSize"] as! NSNumber
        let state = dic["state"] as! String
        let fileSize = (dic["fileSize"] as! NSNumber).longLongValue
        
        let task = DownloadTask(urlStr: urlStr)
        task.recvedSize = recvedSize.longLongValue
        task.state = DownloadTaskState(rawValue: state)!
        task.fileSize = fileSize
        if task.state == .downloading {
            task.state = .failed
        }
        return task
    }
}

//MARK:- task string 
extension DownloadTask{
    public var fileSizeString:String{
        return DownloadUtil.getFileSizeStr(self.fileSize)
    }
    public var recvedSizeString:String{
        return DownloadUtil.getFileSizeStr(self.recvedSize)
    }
    public var speedString:String{
        let speed = self.speed
        return DownloadUtil.getFileSizeStr(speed)
    }
}

//MARK:- downloadFinishedFile
public struct DownloadFinishedFile{
    public var fileName:String
    public var filePath:String
}
//
//  DownloadItem.swift
//  sampleDownloader
//
//  Created by tanson on 16/3/25.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

public enum DownloadItemState{
    case downloading
    case paused
    case failed
}

public class DownloadItem {
    
    public var urlStr:String
    public var name:String {
        return DownloadUtil.getLastNameByURLStr(self.urlStr)
    }
    
    var stream:NSOutputStream!
    var task:NSURLSessionTask?
    
    public var state:DownloadItemState = .paused

    var canRange = false
    public var fileSize:Int64 = -1
    public var recvedSize:Int64 = 0
    public var progress:Int {
        if self.fileSize <= 0 {return 0}
        return Int(Float(recvedSize) / Float(fileSize)*100)
    }
    
    public var speed:Int64 = 0
    var startTime = NSDate()
    var snapshotSize:Int64 = 0
    
    init(urlStr:String){
        self.urlStr = urlStr
    }
    
    //string size
    public var fileSizeString:String{
        if self.fileSize <= 0 { return "未知大小" }
        return DownloadUtil.getFileSizeStr(self.fileSize)
    }
    public var recvedSizeString:String{
        return DownloadUtil.getFileSizeStr(self.recvedSize)
    }
    public var speedString:String{
        return DownloadUtil.getFileSizeStr(self.speed)
    }
    public var progressString:String{
        return String(self.progress) + "%"
    }
    
    public func appendData(data:NSData){
        //objc_sync_enter(self.recveData)
        self.stream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        //objc_sync_exit(self.recveData)
    }
    
    deinit{
        if self.stream != nil{
            self.stream.close()
        }
    }
}

//MARK: 序列化
extension DownloadItem{
    
    func toDictionary()->NSDictionary{
        let dic = NSMutableDictionary()
        dic["url"] = self.urlStr
        dic["fileSize"] = NSNumber(longLong: self.fileSize)
        dic["canRange"] = NSNumber(bool: self.canRange)
        return dic
    }
    
    class func taskFromDictionary(dicData:NSDictionary)-> DownloadItem {
        
        let url = dicData["url"] as! String
        let fileSize = (dicData["fileSize"] as! NSNumber).longLongValue
        let canRange = (dicData["canRange"] as! NSNumber).boolValue
        
        let task = DownloadItem(urlStr: url)
        task.fileSize = fileSize
        task.canRange = canRange
        return task
    }
}

//MARK:- downloadFinishedFile
public struct DownloadFinishedFile{
    public var fileName:String
    public var filePath:String
}
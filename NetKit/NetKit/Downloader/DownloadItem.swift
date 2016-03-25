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
    
    var task:NSURLSessionDownloadTask?
    
    public var state:DownloadItemState = .paused
    //var offset:Int64 = 0
    var fileSize:Int64 = 1
    public var recvedSize:Int64 = 0
    public var progress:Int {
        if self.fileSize <= 1 {return 0}
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
        if self.fileSize <= 1 { return "未知大小" }
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
}


//MARK:- downloadFinishedFile
public struct DownloadFinishedFile{
    public var fileName:String
    public var filePath:String
}
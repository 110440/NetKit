//
//  DownloadUtil.swift
//  DownLoader
//
//  Created by tanson on 16/3/8.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

public typealias downloadFinishedBlock = (task:DownloadTask)->Void
public typealias downloadProgressBlock = (task:DownloadTask,index:Int)->Void
public typealias downloadFinishedErrorBlock = (task:DownloadTask,error:NSError)->Void
public typealias downloadAddUnFinishTaskBlock = (task:DownloadTask)->Void

internal let backgroundSessionIdentifier = (NSBundle.mainBundle().bundleIdentifier)! + "_tt_background_SessionIdentifier"

internal let tasklistPlistName = "tt_downloadManager_tasklist.plist"

public class DownloadUtil {
    
    public class func getFileSizeStr(size:Int64)->String{
        
        func calculateFileSizeInUnit(contentLength : Int64) -> Float {
            let dataLength : Float64 = Float64(contentLength)
            if dataLength >= (1024.0*1024.0*1024.0) {
                return Float(dataLength/(1024.0*1024.0*1024.0))
            } else if dataLength >= 1024.0*1024.0 {
                return Float(dataLength/(1024.0*1024.0))
            } else if dataLength >= 1024.0 {
                return Float(dataLength/1024.0)
            } else {
                return Float(dataLength)
            }
        }
        
        func calculateUnit(contentLength : Int64) -> NSString {
            if(contentLength >= (1024*1024*1024)) {
                return "GB"
            } else if contentLength >= (1024*1024) {
                return "MB"
            } else if contentLength >= 1024 {
                return "KB"
            } else {
                return "Bytes"
            }
        }
        
        let sizeStr = String(format: "%.1f", calculateFileSizeInUnit(size) )
        let sizeUnitStr = String( calculateUnit(size))
        return sizeStr + sizeUnitStr
    }
    
    public class func getFileSizeStrByPath(filePath:String)->String?{
        
        let systemAttributes: AnyObject?
        var fileSize:Int64 = 0
        do {
            systemAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
            let freeSize = systemAttributes?[NSFileSize] as? NSNumber
            fileSize =  freeSize?.longLongValue ?? 0
        } catch let error as NSError {
            print("Error fiel size  Info: Domain = \(error.domain), Code = \(error.code)")
            return nil
        }
        
        return DownloadUtil.getFileSizeStr(fileSize)
    }
    
    
    public class func getFreeDiskspace() -> Int64? {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let systemAttributes: AnyObject?
        do {
            systemAttributes = try NSFileManager.defaultManager().attributesOfFileSystemForPath(documentDirectoryPath.last!)
            let freeSize = systemAttributes?[NSFileSystemFreeSize] as? NSNumber
            return freeSize?.longLongValue
        } catch let error as NSError {
            print("Error Obtaining System Memory Info: Domain = \(error.domain), Code = \(error.code)")
            return nil;
        }
    }
    
    // 
    public class func removPercentForUrlStr(urlStr:String)->String{
        
        var retStr = urlStr.stringByRemovingPercentEncoding
        if retStr == nil{
            let str = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(nil, (urlStr as CFString) ,("" as CFString), UInt32( CFStringEncodings.GB_18030_2000.rawValue))
            retStr = str as String
        }
        if retStr == nil || retStr?.characters.count <= 0 { return "未知文件名" }
        return retStr!
    }

}
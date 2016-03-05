//
//  TTDownloadHelper.swift
//  testTableView
//
//  Created by tanson on 16/3/2.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation


internal let backgroundSessionIdentifier = (NSBundle.mainBundle().bundleIdentifier)! + "_tt_net_SessionIdentifier"

public typealias downloadFinishedBlock = (task:TTDownloadTask)->Void
public typealias downloadProgressBlock = (task:TTDownloadTask,totalBytesWritten:Int64,totalBytesExpectedToWrite:Int64)->Void
public typealias downloadFinishedErrorBlock = (task:TTDownloadTask,error:NSError)->Void

internal let TTDocPath = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first)!

internal func TTGetDownloadPath(directoryName:String)->String{
    
    let downloadPath = (TTDocPath as NSString).stringByAppendingPathComponent(directoryName)
    if !NSFileManager.defaultManager().fileExistsAtPath(downloadPath){
        do{
            try NSFileManager.defaultManager().createDirectoryAtPath(downloadPath, withIntermediateDirectories:true, attributes: nil)
        }catch let error{ print("TTDownloadManager create download dir failed , e:\(error)") }
    }
    return downloadPath
}


public func TTGetFileSizeStr(size:Int64)->String{
    
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

public func TTGetFileSizeStrByPath(filePath:String)->String?{
    
    let systemAttributes: AnyObject?
    var fileSize:Int64 = 0
    do {
        systemAttributes = try NSFileManager.defaultManager().attributesOfFileSystemForPath(filePath)
        let freeSize = systemAttributes?[NSFileSystemFreeSize] as? NSNumber
        fileSize =  freeSize?.longLongValue ?? 0
    } catch let error as NSError {
        print("Error Obtaining System Memory Info: Domain = \(error.domain), Code = \(error.code)")
        return nil
    }
    
    return TTGetFileSizeStr(fileSize)
}


func TTGetFreeDiskspace() -> Int64? {
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

///md5
//extension String  {
//    var tt_md5: String! {
//        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
//        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
//        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
//        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
//        CC_MD5(str!, strLen, result)
//        let hash = NSMutableString()
//        for i in 0..<digestLen {
//            hash.appendFormat("%02x", result[i])
//        }
//        result.dealloc(digestLen)
//        return String(format: hash as String)
//    }
//}
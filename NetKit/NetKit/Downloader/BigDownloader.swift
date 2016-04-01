//
//  Downloader.swift
//  sampleDownloader
//
//  Created by tanson on 16/3/25.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

//MARK:- BigDownloader
public class BigDownloader: NSObject , NSURLSessionDelegate , NSURLSessionDownloadDelegate {
    
    public static let sharedInstance:BigDownloader = {
       let downloader = BigDownloader()
        return downloader
    }()
    
    private func createSession()->NSURLSession {
        var sessionConfiguration:NSURLSessionConfiguration!
        if #available(iOS 8.0, *) {
            sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
        } else {
            sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfiguration(backgroundSessionIdentifier)
        }
        //sessionConfiguration.allowsCellularAccess = false
        return NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue:nil)
    }
    
    public var downloadDirStr = "TTDownloads"
    public var downloadItemList = [DownloadItem]()
    
    private var backgroundSesstion:NSURLSession!
    
    public var completionHandler: (() -> Void)?
    public var taskCompletionHander:taskCompletionBlock?
    public var taskProgressHander:taskProgressBlock?
    public var taskFailedHaner:taskFailedBlock?
    
    private override init() {
        super.init()
        self.backgroundSesstion = self.createSession()
    }
    
    public func startDownloadTask(urlStr:String){
        
        if let downloadItem = self.getDownloadItemByURLStr(urlStr) {
            if  downloadItem.state == .failed || downloadItem.state == .paused{
                downloadItem.startTime      =  NSDate()
                downloadItem.snapshotSize   =  downloadItem.recvedSize
                downloadItem.state          = .downloading
                downloadItem.task?.resume()
            }
            return
        }
        
        let url = NSURL(string: urlStr)
        let req = NSURLRequest(URL: url!)
        let task = self.backgroundSesstion.downloadTaskWithRequest(req)

        let item = DownloadItem(urlStr: urlStr)
        item.task  = task
        item.state = .downloading
        self.downloadItemList.append(item)
        
        task.resume()
    }
    
    public func pausedTaskByURLStr(urlStr:String){
        if let item = self.getDownloadItemByURLStr(urlStr){
            (item.task as? NSURLSessionDownloadTask)?.cancelByProducingResumeData{ _ in }
            item.state = .paused
        }
    }
    
    public func getDownloadItemByURLStr(urlStr:String)->DownloadItem?{
        for item in self.downloadItemList{
            if item.urlStr == urlStr{
                return item
            }
        }
        return nil
    }
    
    //TODO: 多线程问题？
    public func deleteItemByURLStr(urlStr:String){
        var i = 0
        for (index,item) in self.downloadItemList.enumerate(){
            if item.urlStr == urlStr{
                item.task?.cancel()
                i = index
                break
            }
        }
        if i < self.downloadItemList.count{
            self.downloadItemList.removeAtIndex(i)
        }
    }
    
    public var downloadDirectory:NSString?{
        
        let downloadDir = DownloadUtil.documentPath().stringByAppendingPathComponent(self.downloadDirStr)
        if !NSFileManager.defaultManager().fileExistsAtPath(downloadDir){
            do{
                try NSFileManager.defaultManager().createDirectoryAtPath(downloadDir, withIntermediateDirectories: true, attributes: nil)
            }catch let e { print("downloader : create download dir failed :\(e)");return nil }
        }
        return downloadDir as NSString
    }
    
    //MARK: URLSession delegate
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL){
        
        guard let url = downloadTask.originalRequest?.URL else { return}
        let item = self.getDownloadItemByURLStr(url.absoluteString)
        
        guard let downloadDirectory = self.downloadDirectory else{return}
        
        let fileManager = NSFileManager.defaultManager()
        let name = DownloadUtil.getLastNameByURLStr(url.absoluteString)
        let desPath = downloadDirectory.stringByAppendingPathComponent(name)
        
        do{
            if fileManager.fileExistsAtPath(desPath){
                try fileManager.removeItemAtPath(desPath)
            }
            try fileManager.copyItemAtURL(location, toURL: NSURL(fileURLWithPath: desPath))
        }catch let e {
            item?.state = .failed
            print("downloader copy file error: \(e)")
        }
        
    }
    
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print( (downloadTask.response as! NSHTTPURLResponse).statusCode )
        let urlStr = downloadTask.originalRequest?.URL?.absoluteString ?? "未知URL"
        let item = self.getDownloadItemByURLStr(urlStr)
        
        if item == nil || item?.task == nil {
            //print("接收到上次未完成的进度")
            downloadTask.cancelByProducingResumeData{ _ in }
            return
        }else{
            item!.fileSize = totalBytesExpectedToWrite
            item!.recvedSize = totalBytesWritten
            // speed
            if totalBytesWritten < item!.snapshotSize{
                item!.snapshotSize = totalBytesWritten
            }
            let hotSize = totalBytesWritten - item!.snapshotSize
            let downloadTime = NSDate().timeIntervalSinceDate(item!.startTime)
            //downloadTime = downloadTime < 1 ? 1:downloadTime
            let speed = Float(hotSize) / Float( downloadTime )
            item!.speed = Int64(speed)
            
            // save file size
            downloadTask.taskDescription = String(item!.fileSize)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.taskProgressHander?(urlStr: urlStr)
            })
        }

    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        let urlStr = task.originalRequest?.URL?.absoluteString ?? "未知URL"
        let item   = self.getDownloadItemByURLStr(urlStr)
        
        if let error = error{

            let userInfo = error.userInfo ?? [String:AnyObject]()
            if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {

                var resumeDictionary : NSDictionary?
                do {
                    let plistData = try NSPropertyListSerialization.propertyListWithData(resumeData, options: .Immutable, format: nil)
                    resumeDictionary = (plistData as? NSDictionary)
                } catch { }

                //print(resumeDictionary)
                
                let fileSize = task.taskDescription ?? "-1"
                let offset = resumeDictionary?.objectForKey("NSURLSessionResumeBytesReceived") as? NSNumber
                let task   = self.backgroundSesstion.downloadTaskWithResumeData(resumeData)
                
                let downloadItem = DownloadItem(urlStr: urlStr)
                downloadItem.task = task
                downloadItem.recvedSize = offset?.longLongValue ?? 0
                downloadItem.snapshotSize = downloadItem.recvedSize
                downloadItem.fileSize = Int64(fileSize) ?? -1
                
                if item == nil {
                    self.downloadItemList.append(downloadItem)
                }else{
                    item!.task          = task
                    item!.state         = downloadItem.state
                    item!.snapshotSize  = downloadItem.snapshotSize
                    item!.recvedSize    = downloadItem.recvedSize
                    item!.fileSize      = downloadItem.fileSize
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.taskProgressHander?(urlStr:urlStr)
                })
                
            }else{
                print(error)
                item?.state = .failed
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.taskFailedHaner?(urlStr: urlStr, error: error)
                })
            }
            
        }else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.deleteItemByURLStr(urlStr)
                self.taskCompletionHander?(urlStr: urlStr)
            })
        }
    }
    
    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        //print("URLSessionDidFinishEventsForBackgroundURLSession")
        if let completionHandler = self.completionHandler{
            completionHandler()
            self.completionHandler = nil
        }
    }
}


// MARK:- 下载完成列表
extension BigDownloader{
    
    public func getDownloadFiniedList()->[DownloadFinishedFile]{
        
        var downloadFinishedList = [DownloadFinishedFile]()
        guard let downloadDirectory = self.downloadDirectory else{return downloadFinishedList}
        
        let fileManger = NSFileManager.defaultManager()
        var contentOfDir:[String]
        do {
            contentOfDir = try fileManger.contentsOfDirectoryAtPath(downloadDirectory as String)
            for fileName in contentOfDir{
                if fileName != ".DS_Store"  {
                    let filePath = downloadDirectory.stringByAppendingPathComponent(fileName)
                    let downloadFinishedFile = DownloadFinishedFile(fileName:fileName   ,filePath:filePath )
                    downloadFinishedList.append(downloadFinishedFile)
                }
            }
            return downloadFinishedList
        } catch let error as NSError {
            print("DownloadManager: downloadFiniedList() Error while getting directory content \(error)")
            return downloadFinishedList
        }
    }
    
    public func deleteFinishedFile(fileName:String){

        guard let downloadDirectory = self.downloadDirectory else{return}
        let filePath = downloadDirectory.stringByAppendingPathComponent(fileName)
        if NSFileManager.defaultManager().fileExistsAtPath(filePath){
            do{
                try NSFileManager.defaultManager().removeItemAtPath(filePath)
            }catch{
                
            }
        }
    }//end
    
}

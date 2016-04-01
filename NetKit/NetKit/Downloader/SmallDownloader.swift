//
//  Downloader.swift
//  sampleDownloader
//
//  Created by tanson on 16/3/25.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

private let downloatTaskPlistName = "downloadTasks.plist"

//MARK:- SmallDownloader
public class SmallDownloader: NSObject , NSURLSessionDelegate,NSURLSessionDataDelegate {
    
    private let writeQueue = dispatch_queue_create("tt_downloader_write_file", nil)
    
    public var timeoutInterval:NSTimeInterval = 30
    private var session:NSURLSession {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
        return NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue:nil)
    }
    
    public var downloadDirStr:String
    private var taskListFilePath:String?{
        return self.downloadDirectory?.stringByAppendingPathComponent(downloatTaskPlistName)
    }
    
    public var downloadItemList = [DownloadItem]()
    
    public var completionHandler: (() -> Void)?
    public var taskCompletionHander:taskCompletionBlock?
    public var taskProgressHander:taskProgressBlock?
    public var taskFailedHaner:taskFailedBlock?
    
    public init(dir:String , forBackground:Bool = true ) {
        self.downloadDirStr = dir
        super.init()
        self.loadTaskList()
        if forBackground{
            self.addObserverForBackground()
        }
    }
    
    private func addObserverForBackground(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"appEnterBackground", name:UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    @objc private func appEnterBackground(){
        var bgTask:UIBackgroundTaskIdentifier!
        bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        }
    }
    
    private func getDesFilePathForItem(item:DownloadItem)->String?{
        guard let downloadDirectory = self.downloadDirectory else {return nil}
        let path = downloadDirectory.stringByAppendingPathComponent(item.name)
        if !NSFileManager.defaultManager().fileExistsAtPath(path){
            if NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil) == false{
                return nil
            }
        }
        return path
    }
    
    public func startDownloadTask(urlStr:String){
        
        var downloadItem:DownloadItem!
        
        if let item = self.getDownloadItemByURLStr(urlStr) {
            if  item.state == .failed || item.state == .paused{
                downloadItem = item
            }else{
                return
            }
        }
        
        if downloadItem == nil {
            downloadItem = DownloadItem(urlStr: urlStr)
            self.downloadItemList.append(downloadItem)
        }
        
        guard let itemDesFilePath = self.getDesFilePathForItem(downloadItem) else {return}
        
        if downloadItem.task == nil{
            
            let url = NSURL(string: urlStr)
            let req = NSMutableURLRequest(URL: url!)
            
            let startPos = DownloadUtil.getFileSizeByPath(itemDesFilePath)
            if startPos > 0 && downloadItem.canRange {
                let rangeHeadStr = "bytes=\(startPos)-"
                req.setValue(rangeHeadStr, forHTTPHeaderField: "Range")
                let task = self.session.dataTaskWithRequest(req)
                downloadItem.task = task
                downloadItem.recvedSize = startPos
            }else{
                let task = self.session.dataTaskWithRequest(req)
                downloadItem.task = task
                downloadItem.recvedSize = 0
                if startPos > 0{ // 服务器不支持断点续传
                    let _ = try? NSFileManager.defaultManager().removeItemAtPath(itemDesFilePath)
                    if !NSFileManager.defaultManager().createFileAtPath(itemDesFilePath, contents: nil, attributes: nil){
                        return
                    }
                }
            }
            downloadItem.stream = NSOutputStream(toFileAtPath: itemDesFilePath, append: true)
        }
        
        downloadItem.startTime      =  NSDate()
        downloadItem.snapshotSize   =  downloadItem.recvedSize
        downloadItem.state          = .downloading
        downloadItem.task!.resume()
        self.saveTaskList()
    }
    
    public func pausedTaskByURLStr(urlStr:String){
        if let item = self.getDownloadItemByURLStr(urlStr){
            item.task?.suspend()
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
    //只移除item不删除对应文件
    public func removeDownloadItemByUrl(urlStr:String)->DownloadItem?{
        var i = -1
        var downloadItem:DownloadItem?
        for (index,item) in self.downloadItemList.enumerate() {
            if item.urlStr == urlStr{
                i = index
                item.task?.cancel()
                downloadItem = item
                break
            }
        }
        if i >= 0 && i < self.downloadItemList.count{
            self.downloadItemList.removeAtIndex(i)
        }
        self.saveTaskList()
        return downloadItem
    }
    //移除item并删除文件
    public func deleteItemByURLStr(urlStr:String ){
        if let downloadItem = self.removeDownloadItemByUrl(urlStr){
            if let itemDesFilePath = self.getDesFilePathForItem(downloadItem) {
                let _ =  try? NSFileManager.defaultManager().removeItemAtPath(itemDesFilePath)
            }
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
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData){

        let urlStr = dataTask.originalRequest?.URL?.absoluteString ?? "未知URL"
        guard let item = self.getDownloadItemByURLStr(urlStr) else {return}

        //save to file
        item.appendData(data)
        item.recvedSize += data.length
        
        // speed
        let hotSize = item.recvedSize - item.snapshotSize
        let downloadTime = NSDate().timeIntervalSinceDate(item.startTime)
        //downloadTime = downloadTime < 1 ? 1:downloadTime
        let speed = Float(hotSize) / Float( downloadTime )
        item.speed = Int64(speed)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.taskProgressHander?(urlStr: urlStr)
        })
        
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        let urlStr = dataTask.originalRequest?.URL?.absoluteString ?? "未知URL"
        guard let item = self.getDownloadItemByURLStr(urlStr) else {return}
        
        let totalContentLength = response.expectedContentLength
        let httpResponse = response as! NSHTTPURLResponse
        
        print(" statusCode:\(httpResponse.statusCode) ")
        
        let contentRange = (httpResponse.allHeaderFields["Accept-Ranges"] as? String) ?? ""
        if contentRange.hasPrefix("bytes"){
            item.canRange = true
        }else{
            item.canRange = false
        }
        
        if(httpResponse.statusCode == 206) {
            /*
            if contentRange.hasPrefix("bytes"){
                let bytes = contentRange.componentsSeparatedByString(" -/")
                if bytes.count == 4 {
                    let fileOffset = Int64(bytes[1]) ?? 0
                    let totalContentLength = Int64(bytes[3]) ?? 0
                    print("fileOffset:\(fileOffset) totalContentLength(\(totalContentLength))")
                }
            }*/
        }else if (response as! NSHTTPURLResponse).statusCode != 200 {
            
            completionHandler(NSURLSessionResponseDisposition.Cancel)
            item.state = .failed
            item.task = nil
            item.stream.close()
            
            let error = NSError(domain: "下载失败", code: -1, userInfo: nil)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.taskFailedHaner?(urlStr: urlStr, error: error)
            })
            return
        }
        
        item.fileSize = totalContentLength + item.recvedSize
        item.stream.open()
        self.saveTaskList()
        
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        let urlStr = task.originalRequest?.URL?.absoluteString ?? "未知URL"
        guard let item = self.getDownloadItemByURLStr(urlStr) else {return}
        
        if let error = error{

            item.state = .failed
            item.task = nil
            item.stream.close()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.taskFailedHaner?(urlStr: urlStr, error: error)
            })
            
        }else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeDownloadItemByUrl(urlStr)
                self.taskCompletionHander?(urlStr: urlStr)
            })
        }
    }
    
}

//MARK: save & load
extension SmallDownloader{

    private func loadTaskList() {
        
        dispatch_sync(writeQueue) {
            guard let plistFilePath = self.taskListFilePath else{return}
            guard let itemArray:NSMutableArray = NSMutableArray(contentsOfFile:plistFilePath) else { return }
            
            for itemData in itemArray {
                guard let itemData = itemData as? NSDictionary else { return }
                let item = DownloadItem.taskFromDictionary(itemData)
                self.downloadItemList.append(item)
            }
        }
    }
    
    private func saveTaskList() {
        dispatch_sync(writeQueue) {
            guard let plistFilePath = self.taskListFilePath else{return}
            let taskArry = NSMutableArray()
            for item in self.downloadItemList {
                let task = item.toDictionary()
                taskArry.addObject(task)
            }
            taskArry.writeToFile(plistFilePath, atomically: true )
        }
    }
}


// MARK:- 下载文件,完成列表
extension SmallDownloader{
    
    private func isFileDownloadFinished(fileName:String)->Bool{
        for item in self.downloadItemList{
            if fileName == item.name{
                return false
            }
        }
        return true
    }
    
    public func getDownloadFiniedList()->[DownloadFinishedFile]{
        
        var downloadFinishedList = [DownloadFinishedFile]()
        guard let downloadDirectory = self.downloadDirectory else{return downloadFinishedList}
        
        let fileManger = NSFileManager.defaultManager()
        var contentOfDir:[String]
        do {
            contentOfDir = try fileManger.contentsOfDirectoryAtPath(downloadDirectory as String)
            for fileName in contentOfDir{
                if isFileDownloadFinished(fileName) && fileName != ".DS_Store" && fileName != downloatTaskPlistName {
                    let filePath = downloadDirectory.stringByAppendingPathComponent(fileName)
                    let downloadFinishedFile = DownloadFinishedFile(fileName:fileName,filePath:filePath )
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
            let _ = try? NSFileManager.defaultManager().removeItemAtPath(filePath)
        }
    }
    
    public func deleteAllUnfinishedFile(){
        for item in self.downloadItemList{
            self.deleteItemByURLStr(item.urlStr)
        }
    }
    
}

//
//  DownloadManager.swift
//  DownLoader
//
//  Created by tanson on 16/3/8.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import UIKit

public class DownloadManager:NSObject,NSURLSessionDelegate,NSURLSessionDownloadDelegate {
    
    private lazy var session:NSURLSession = {
        let sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
        sessionConfiguration.timeoutIntervalForRequest = 15
        return NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()
    
    public var taskList = [DownloadTask]()
    public var downloadDir:String
    
    //callback
    public var downloadFinied:downloadFinishedBlock?
    public var downloadProgress:downloadProgressBlock?
    public var downloadError:downloadFinishedErrorBlock?
    public var downloadAddUnfinishTask:downloadAddUnFinishTaskBlock?
    
    //后台模式，要在 AppDelegate handleEventsForBackgroundURLSession 里面对此变量赋值
    public var completionHandler:(()->Void)?
    
    public init(dir:String) {
        self.downloadDir = dir
        super.init()
        self.loadTaskList()
        self.session.configuration //手动创建session，重启后接收上次数据
    }
    
    private func createTaskByURLStr(urlStr:String)->DownloadTask{
        
        let downloadTask = DownloadTask(urlStr: urlStr)
        let offSet = self.cacheFileSizeForTask(downloadTask)
        let rangeHeadStr = "bytes=\(offSet)-"
        let request = NSMutableURLRequest(URL:NSURL(string: downloadTask.urlStr)!)
        request.setValue(rangeHeadStr, forHTTPHeaderField: "Range")
        
        let task = self.session.downloadTaskWithRequest(request)
        task.taskDescription = urlStr
        
        downloadTask.rawTask = task
        downloadTask.offset  = offSet
        downloadTask.recvedSize = offSet
        return downloadTask
    }
    
    public func newTask(urlStr:String)->String?{
        
        guard let _ = NSURL(string: urlStr) else {return nil}
        guard self.taskByURLStr(urlStr) == nil else {return nil}
        
        let downloadTask = self.createTaskByURLStr(urlStr)
        self.taskList.append(downloadTask)
        self.saveTaskList()
        downloadTask.resume()
        return urlStr
    }
    
    public func stopOrStartTaskByURLStr(urlStr:String){
        guard let downloadTask = self.taskByURLStr(urlStr) else {return}
        if downloadTask.rawTask == nil {
            let newDownloadTask     = self.createTaskByURLStr(downloadTask.urlStr)
            downloadTask.rawTask    = newDownloadTask.rawTask
            downloadTask.offset     = newDownloadTask.offset
            downloadTask.recvedSize = newDownloadTask.recvedSize
        }
        downloadTask.pauseOrResume()
        
        //刷新状态
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let progress = self.downloadProgress{
                progress(task: downloadTask,index:self.indexOfDownloadTaskInList(downloadTask) )
            }
        })
    }
    
    private var downloadDirFullPath:NSString?{
        let docPath = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first)!
        let downloadFullPath = (docPath as NSString).stringByAppendingPathComponent(self.downloadDir)
        if !NSFileManager.defaultManager().fileExistsAtPath(downloadFullPath){
            do{
                try NSFileManager.defaultManager().createDirectoryAtPath(downloadFullPath, withIntermediateDirectories:true, attributes: nil)
            }catch let error{
                print("DownloadManager create download dir failed , e:\(error)")
                return nil
            }
        }
        return downloadFullPath
    }
    
    private func destinationPathForTask(task:DownloadTask)->String?{
        return self.downloadDirFullPath?.stringByAppendingPathComponent(task.fileName)
    }
    private func cachePathForTask(task:DownloadTask)->String?{
        guard let path = self.downloadDirFullPath?.stringByAppendingPathComponent(task.tempFileName) else {return nil}
        if !NSFileManager.defaultManager().fileExistsAtPath(path){
            NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
        }
        return path
    }
    
    private func deleteCacheFileForTask(task:DownloadTask){
        guard let path = self.cachePathForTask(task) else {return}
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        }catch let e{
            print("DownloadManager delete cache file error :\(e)")
        }
    }
    
    public func taskByIndex(index:Int)->DownloadTask?{
        return self.taskList[index]
    }
    
    public func deleteTask(task:DownloadTask){
        self.taskList = self.taskList.filter{ $0.urlStr != task.urlStr }  //1
        self.saveTaskList()
        task.cancell() //2
    }
    
    public func indexOfDownloadTaskInList(task:DownloadTask)->Int{

        var index = 0
        for downloadTask in self.taskList{
            if downloadTask.urlStr == task.urlStr{
                return index
            }else{
                index++
            }
        }
        return -1
    }
    
    public func taskByURLStr(urlStr:String?)->DownloadTask?{
        if urlStr == nil { return nil}
        for downloadTask in self.taskList{
            if downloadTask.urlStr == urlStr {
                return downloadTask
            }
        }
        return nil
    }
    
    // MARK: - NSURLSession Delegates -
    ///////////////////////////////////////////////////

    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let task = self.taskByURLStr(downloadTask.taskDescription) else {return}
        if task.rawTask == nil { return } // 重启后任务还未开始莫名的接收到数据
        
        task.recvedSize = totalBytesWritten + task.offset
        
        // save file size
        if task.fileSize <= 0{
            task.fileSize = totalBytesExpectedToWrite + task.offset
            self.saveTaskList()
        }
        
        // speed
        if let startTime = task.startTime{
            let hotSize = totalBytesWritten - task.coldSize
            var downloadTime = NSDate().timeIntervalSinceDate(startTime)
            downloadTime = downloadTime < 1 ? 1:downloadTime
            let speed = Float(hotSize) / Float( downloadTime )
            task.speed = Int64(speed)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let progress = self.downloadProgress{
                progress(task: task,index:self.indexOfDownloadTaskInList(task) )
            }
        })
    }
    
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        let fileManager : NSFileManager! = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(location.path!) { print("DownloadManager: didFinishDownloadingToURL() location 不存在") ; return }

        guard let downloadTask = self.taskByURLStr(downloadTask.taskDescription) else {return}
        guard let destinationPath = self.destinationPathForTask(downloadTask) else {return}
        
        let fileURL: NSURL = NSURL(fileURLWithPath: destinationPath)
        
        do {
            if fileManager.fileExistsAtPath(destinationPath){
                try fileManager.removeItemAtPath(destinationPath)
            }
            
            // 如果曾经下载过,合并文件
            if self.cacheFileSizeForTask(downloadTask) > 0 {
                
                fileManager.createFileAtPath(destinationPath, contents: nil, attributes: nil)
                
                guard let fileHandle = NSFileHandle(forWritingAtPath: destinationPath) else {
                    print("DownloadManager: didFinishDownloadingToURL NSFileHandle create error")
                    return
                }
                
                do{
                    let cacheFileData = try NSData(contentsOfFile: self.cachePathForTask(downloadTask)!, options: [.DataReadingMapped] )
                    fileHandle.writeData(cacheFileData)
                    fileHandle.seekToEndOfFile()
                    
                    let newFileData  = try NSData(contentsOfFile: location.path! , options: [.DataReadingMapped] )
                    fileHandle.writeData(newFileData)
                    fileHandle.synchronizeFile()
                    fileHandle.closeFile()
                    
                }catch let e{
                    print("DownloadManager: didFinishDownloadingToURL error: \(e)")
                }
                
            }else{
                try fileManager.moveItemAtURL(location, toURL: fileURL)
            }
            self.deleteCacheFileForTask(downloadTask)
        } catch let error as NSError {
            print("DownloadManager :Error while moving downloaded file to destination path:\(error)")
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        guard let downloadTask = self.taskByURLStr(task.taskDescription) else {return}
        
        if let error = error {
            //print("downloadError:\(error)")
            if error.code == NSURLErrorCancelledReasonInsufficientSystemResources{
                downloadTask.rawTask = nil
                downloadTask.state = .failed
                dispatch_async(dispatch_get_main_queue()) {
                    if let errorBlock = self.downloadError{
                        errorBlock(task: downloadTask, error: error)
                    }
                }
                return
            }

            if let errorUserInfo : NSDictionary = error.userInfo{
                if let resumeData = errorUserInfo.objectForKey(NSURLSessionDownloadTaskResumeData) as? NSData {
                    self.saveResumeData(resumeData, forTask: downloadTask)
                }
            }
            
            let newDownloadTask     = self.createTaskByURLStr(downloadTask.urlStr)
            downloadTask.rawTask    = newDownloadTask.rawTask
            downloadTask.recvedSize = newDownloadTask.recvedSize
            downloadTask.offset     = newDownloadTask.offset
            downloadTask.state      = .paused
            self.saveTaskList()
            
            dispatch_async(dispatch_get_main_queue()) {
                if let errorBlock = self.downloadError{
                    errorBlock(task: downloadTask , error: error)
                }
                if let progress = self.downloadProgress{
                    progress(task: downloadTask, index: self.indexOfDownloadTaskInList(downloadTask) )
                }
            }
            
        }else {

            dispatch_async(dispatch_get_main_queue(), { () -> Void in

                self.deleteTask(downloadTask)
                if let finished = self.downloadFinied{
                    let filePath = self.destinationPathForTask(downloadTask)
                    print(filePath)
                    finished(task: downloadTask)
                }
            })
        }
        
    }
    
    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {

        if let completionHandler = self.completionHandler{
            completionHandler()
            self.completionHandler = nil
        }
    }
}


// MARK:- 下载完成列表
extension DownloadManager{
    
    public func getDownloadFiniedList()->[DownloadFinishedFile]{
        
        var downloadFinishedList = [DownloadFinishedFile]()
        guard let downloadDirPath = self.downloadDirFullPath else {return downloadFinishedList}
        
        let fileManger = NSFileManager.defaultManager()
        var contentOfDir:[String]
        do {
            contentOfDir = try fileManger.contentsOfDirectoryAtPath(downloadDirPath as String)
            for fileName in contentOfDir{
                if fileName != ".DS_Store" && fileName != tasklistPlistName && !fileName.hasSuffix(".temp") {
                    let filePath = downloadDirPath.stringByAppendingPathComponent(fileName)
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
        guard let downloadDirPath = self.downloadDirFullPath else {return}
        let filePath = downloadDirPath.stringByAppendingPathComponent(fileName)
        if NSFileManager.defaultManager().fileExistsAtPath(filePath){
            do{
                try NSFileManager.defaultManager().removeItemAtPath(filePath)
            }catch{
                
            }
        }
    }
}

//MARK:- resumeData 处理
extension DownloadManager{
    
    private func getResumeDataFilePath(resumeData:NSData)->String?{
        
        if resumeData.length < 0 { return nil }
        
        var resumeDictionary : NSDictionary?
        do {
            resumeDictionary = try NSPropertyListSerialization.propertyListWithData(resumeData, options: .Immutable, format: nil) as?NSDictionary
        } catch {return nil}
        
        //print(resumeDictionary )
        
        guard let resumeDataDic = resumeDictionary else {return nil}
        guard let resumeDataVersion = resumeDataDic["NSURLSessionResumeInfoVersion"] as? Int else{return nil }
        
        var cacheFilePath:String? = nil
        
        switch resumeDataVersion{
        case 2:
            guard let tempFileName = resumeDataDic["NSURLSessionResumeInfoTempFileName"] as? String else {return nil}
            let tempDirPath = NSTemporaryDirectory()
            cacheFilePath = (tempDirPath as NSString).stringByAppendingPathComponent(tempFileName)
        case 1:
            guard let tempFilePath = resumeDataDic["NSURLSessionResumeInfoLocalPath"] as? String else{return nil}
            cacheFilePath = tempFilePath
        default:
            print("TTDownloadManager resumeData 解析出错 resumeDataVersion;\(resumeDataVersion)")
            return nil
        }
        
        return cacheFilePath
    }
    
    private func cacheFileSizeForTask(task:DownloadTask)->Int64{
        guard let filePath = self.cachePathForTask(task) else {return 0}
        let systemAttributes: AnyObject?
        do {
            systemAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
            let size = systemAttributes?[NSFileSize] as? NSNumber
            return size?.longLongValue ?? 0
        } catch let error as NSError {
            print("resumeDataSizeForTask error ,Info: Domain = \(error.domain), Code = \(error.code)")
            return 0
        }
    }
    
    private func saveResumeData(resumeData:NSData,forTask:DownloadTask){
        
        guard let appendDataPath = self.getResumeDataFilePath(resumeData) else{return}
        guard let cacheFilePath = self.cachePathForTask(forTask) else {return}
        
        do{
            let appendData = try NSData(contentsOfFile: appendDataPath, options: NSDataReadingOptions.DataReadingMapped )
            guard let cacheFileHandle = NSFileHandle(forWritingAtPath: cacheFilePath) else {
                print("DownloadManager saveResumeData error ")
                return
            }
            cacheFileHandle.seekToEndOfFile()
            cacheFileHandle.writeData(appendData)
            cacheFileHandle.synchronizeFile()
            cacheFileHandle.closeFile()
        }catch let error {
            print("DownloadManager saveResumeData copy cache file error:\(error) ")
        }
        
    }
    
    private func isResumeDataExistForTask(task:DownloadTask)->Bool{
        return false
    }
}


//MARK:- serialization
extension DownloadManager{
    
    private var tasklistFilePath:String?{
        return self.downloadDirFullPath?.stringByAppendingPathComponent(tasklistPlistName)
    }
    
    private func loadTaskList() {
        
        guard let localFilePath = self.tasklistFilePath else{return}
        guard let itemArray:NSMutableArray = NSMutableArray(contentsOfFile:localFilePath) else { return }
        
        for itemData in itemArray {
            guard let item:NSDictionary = itemData as? NSDictionary else { return }
            let task = DownloadTask.fromDictionary(item)
            self.taskList.append(task)
        }
    }
    
    private func saveTaskList() {
        
        guard let localFilePath = self.tasklistFilePath else{return}
        let taskArry = NSMutableArray()
        for task in taskList {
            let item = task.toDictionary()
            taskArry.addObject(item)
        }
        taskArry.writeToFile(localFilePath, atomically: true )
    }
}
//
//  DonwloadManager.swift
//  NetKit
//
//  Created by tanson on 16/2/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

//MARK:- DownloadManager
public class TTDownloadManager : NSObject, NSURLSessionDownloadDelegate , NSURLSessionDelegate,NSURLSessionTaskDelegate {
    
    // 下载文件存放目录，可创建多个不同目录的 DownloadManager
    private let downloadDir:String
    
    private let backgroundEnable:Bool
    
    public var timeout:Double = 15.0
    
    //后台模式，要在 AppDelegate handleEventsForBackgroundURLSession 里面对此变量赋值
    public var completionHandler:(()->Void)?
    
    private lazy var taskListFilePath:String = {
        return ( TTGetDownloadPath( self.downloadDir ) as NSString).stringByAppendingPathComponent("TTdownloadList.plist")
    }()
    
    private lazy var session:NSURLSession = {
        let q = NSURLSession.sharedSession().delegateQueue
        let c:NSURLSessionConfiguration?
        if self.backgroundEnable {
            c = NSURLSessionConfiguration.backgroundSessionConfiguration(backgroundSessionIdentifier)
        }else{
            c = NSURLSessionConfiguration.defaultSessionConfiguration()
        }
        c?.timeoutIntervalForRequest = self.timeout
        let s = NSURLSession(configuration: c!, delegate: self, delegateQueue: q )
        return s
    }()
    
    // callBack
    public var finishedBlock:downloadFinishedBlock?
    public var progressBlock:downloadProgressBlock?
    public var finishedWithErrorBlock:downloadFinishedErrorBlock?
    public func finishedBlock(block:downloadFinishedBlock)->Self{
        self.finishedBlock = block
        return self
    }
    public func progressBlock(block:downloadProgressBlock)->Self{
        self.progressBlock = block
        return self
    }
    public func finishedWithErrorBlock(block:downloadFinishedErrorBlock)->Self{
        self.finishedWithErrorBlock = block
        return self
    }
    
    
    public var taskList = [TTDownloadTask]()
    
    public var finishedList:[TTDownloadTask] {
        return self.taskList.filter{ $0.finished }
    }
    public var unFinishedList:[TTDownloadTask] {
        return self.taskList.filter{ !$0.finished }
    }
    
    public init(downloadDir:String,backgroundEnable:Bool = false ) {
        
        self.downloadDir = downloadDir
        self.backgroundEnable = backgroundEnable
        super.init()
        self.loadTaskList()
    }
    
    //MARK: save & load list
    
    private func loadTaskList() {
        
        guard let itemArray:NSMutableArray = NSMutableArray(contentsOfFile: self.taskListFilePath) else { return }
        
        for itemData in itemArray {
            guard let item:NSDictionary = itemData as? NSDictionary else { return }
            let task = TTDownloadTask.taskFromDictionary(item)
            task.session = self.session
            self.taskList.append(task)
        }
    }
    
    private func saveTaskList() {
        
        let taskArry = NSMutableArray()
        for task in taskList {
            let item = task.toDictionary()
            taskArry.addObject(item)
        }
        taskArry.writeToFile(self.taskListFilePath, atomically: true )
    }

    public func newTask(urlStr:String)->TTDownloadTask?{
        
        if let _ = self.taskByURLStr(urlStr) { return nil }
        guard let _ = NSURL(string: urlStr) else { print("TTDownload newTask url;\(urlStr) 不合法 ") ;return nil}
        
        let task = TTDownloadTask(urlStr: urlStr , dir: self.downloadDir)
        task.session = self.session
        self.taskList.append(task)
        self.saveTaskList()
        task.resume()
        
        return task
    }
    
    public func taskByURLStr(URLStr:String)->TTDownloadTask?{
        return self.taskList.filter{ $0.url == NSURL(string: URLStr) }.first
    }
    
    public func taskByIndex(idx:Int)->TTDownloadTask?{
        return self.taskList[idx]
    }
    
    public func startAllUnfinishTask(){
        let tasks = self.unFinishedList
        for task in tasks{
            task.resume()
        }
    }
    
    public func deleteTaskByURL(taskURLStr:String){

        self.taskList = self.taskList.filter{
            
            if $0.url == NSURL(string: taskURLStr){
                $0.deleteLocalFile()
                return false
            }else{
                return true
            }
        }
        self.saveTaskList()
    }
    
    public func deleteTaskByIndex(idx:Int){
        if let task = self.taskByIndex(idx){
            self.deleteTaskByURL(task.url.absoluteString)
        }
    }
    
    //MARK: downloadTask delegate
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        if !NSFileManager.defaultManager().fileExistsAtPath(location.path!){  print("location 不存在") ; return }
        
        guard let downloadURL = downloadTask.originalRequest?.URL?.absoluteString else { return }
        
        guard let task = self.taskByURLStr(downloadURL) else { print("TTDownloadManager : 找不到对应的 donwnloadTask "); return}
        
        let filePath = task.filePath
        do{
            if NSFileManager.defaultManager().fileExistsAtPath(filePath){
                try! NSFileManager.defaultManager().removeItemAtPath(filePath)
            }
            // 如果曾经下载过,合并文件
            if let resumeData = task.resumeData{
                
                NSFileManager.defaultManager().createFileAtPath(filePath, contents: nil, attributes: nil)
                
                let fileHandle = NSFileHandle(forWritingAtPath: filePath)
                fileHandle?.writeData(resumeData)
                fileHandle?.seekToEndOfFile()
                
                let appenData = NSData(contentsOfFile: location.path! )
                fileHandle?.writeData(appenData ?? NSData() )
                fileHandle?.synchronizeFile()
                fileHandle?.closeFile()
                
                task.deleteCachefile()
            }else{
                try NSFileManager.defaultManager().moveItemAtURL(location, toURL:NSURL.fileURLWithPath(filePath))
            }
            
            task.state = .Completed
            task._finished = true
            
            if let finish = self.finishedBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    finish(task: task)
                })
            }
            
        }catch let error {
            
            task.state = .Failed
            print( "TTDownloadManager : moveItemAtURL failed e:\(error)")
            if let errorHandle = self.finishedWithErrorBlock{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    errorHandle(task: task, error: error as NSError)
                })

            }
        }
        
        self.saveTaskList()
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        guard let e = error else { return }
        guard let task = self.taskByURLStr((task.response?.URL?.absoluteString)!) else {return}
        
        if let resumeData = error?.userInfo[NSURLSessionDownloadTaskResumeData] as? NSData {
            
            let resumeDic:NSDictionary?
            do{
                resumeDic = try NSPropertyListSerialization.propertyListWithData(resumeData, options:.Immutable, format: nil) as? NSDictionary
            }catch let e { print("TTDownloadManager 解析 resumeData 出错! e:\(e)") ;return }
            
            //print(" resumeDic \(resumeDic!) ")
            
            var tempFilePath:String? = nil
            if let resumeDataVersion = resumeDic!["NSURLSessionResumeInfoVersion"] as? Int {
                if resumeDataVersion == 2 {
                    let tempFileName = resumeDic!["NSURLSessionResumeInfoTempFileName"] as! String
                    let tempDirPath = NSTemporaryDirectory()
                    tempFilePath = (tempDirPath as NSString).stringByAppendingPathComponent(tempFileName)
                    
                    let tempFileData = NSData(contentsOfFile: tempFilePath!)
                    task.resumeData = tempFileData
                    
                }else if resumeDataVersion == 1{
                    let tempFilePath = resumeDic!["NSURLSessionResumeInfoLocalPath"] as! String
                    let tempFileData = NSData(contentsOfFile: tempFilePath)
                    task.resumeData = tempFileData
                    
                }else{
                    print("TTDownloadManager resumeData 解析出错 resumeDataVersion;\(resumeDataVersion)")
                }
            }
        }
        
        if e.code == NSURLErrorCancelled {
            task.state = .Suspended
        }else{
            task.state = .Failed
            if let finishedWithError = self.finishedWithErrorBlock{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    finishedWithError(task: task, error: e)
                })
            }
        }
        self.saveTaskList()
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let task = self.taskByURLStr((downloadTask.response?.URL?.absoluteString)!) else {
            print("TTDownloadManager :找不到 task ")
            return
        }
        
        if totalBytesExpectedToWrite <= 0 {
            //print("TTDownloadManager :服务器没有提供文件长度信息")
        }else if task.fileSize <= 0 {
            task.fileSize = task.resumeSize + totalBytesExpectedToWrite
            self.saveTaskList()
        }
        
        task.totalBytesWritten = totalBytesWritten
        task.totalBytesExpectedToWrite = totalBytesExpectedToWrite
        
        if let progress = self.progressBlock {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                progress(task: task, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            })
        }
    }
    
    //MARK:- URLSesstionDelegate
    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession){
        if self.backgroundEnable == false { return }
        if let handler = self.completionHandler{
            handler()
            self.completionHandler = nil
        }
    }
    
}
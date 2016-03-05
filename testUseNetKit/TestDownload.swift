//
//  TestDownload.swift
//  testUseNetKit
//
//  Created by tanson on 16/3/4.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import NetKit

private var urlStrs = [
    "http://jsdx1.downg.com//201602/langdunv_7.3_DownG.com.rar",
    "http://big.236.xdowns.com/g/%CE%D2%B5%C4%CA%C0%BD%E7.rar",
    "http://zjdx.downg.com//201602/xiaoqReader2.10.0.159_DownG.com.rar",
    "http://pic.pp3.cn/uploads//allimg/111116/110213Nb-0.jpg",
    "http://pic.pp3.cn/uploads//allimg/111116/1102135554-1.jpg",
    "http://pic.pp3.cn/uploads//allimg/111116/11021321R-4.jpg"
]

let gd = TTDownloadManager(downloadDir: "TTDownload", backgroundEnable: true)


class TestDownload :UITableViewController {
    
    
    lazy var downloader:TTDownloadManager = {
        let d = gd
        
        d.finishedBlock{ [weak self] (task) -> Void in
            print(task.filePath)
            self?.tableView.reloadData()
        }.progressBlock{ [weak self] (task, totalBytesWritten, totalBytesExpectedToWrite) -> Void in
            self?.tableView.reloadData()
        }.finishedWithErrorBlock{ (task, error) -> Void in
            print(error)
        }
        return d
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "DownloadManager"
        self.view.backgroundColor = UIColor.whiteColor()
        let barItem = UIBarButtonItem(title: "增加", style: .Plain, target: self, action: "addDownload")
        self.navigationItem.rightBarButtonItem = barItem
        
        self.tableView.registerNib(UINib(nibName: "DownloadCellTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 58.0
        
    }
    
    func addDownload(){
        guard urlStrs.count > 0 else {return}
        let urlstr = urlStrs.removeLast()
        self.downloader.newTask(urlstr)
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloader.taskList.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let task = self.downloader.taskList[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("cell",forIndexPath: indexPath) as! DownloadCellTableViewCell
        cell.fileName.text = task.fileName
        cell.progress.text = (String(task.progress) + "%")
        
        var curSizeStr = "未知文件大小"
        if task.fileSize > 0 {
            
            curSizeStr = "\(task.stringForFileSizeWritten) / \(task.StringForFileSize) "
        }
        cell.cureentSize.text = curSizeStr
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let task  = self.downloader.taskList[indexPath.row]
        if task.state == .Running{
            task.suspend()
        }else if task.state == .Failed || task.state == .Suspended {
            task.resume()
        }
        
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete{
            self.downloader.deleteTaskByIndex(indexPath.row)
            self.tableView.reloadData()
        }
    }
    
}
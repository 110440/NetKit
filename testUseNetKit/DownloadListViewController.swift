//
//  ViewController.swift
//  DownLoader
//
//  Created by tanson on 16/3/8.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import NetKit


private var urlStrs = [
    "http://www.xiaoxiongbizhi.com/wallpapers/__85/b/4/b4fpslb55.jpg",
    "http://www.xiaoxiongbizhi.com/wallpapers/__85/2/q/2q7p10bs6l.jpg",
    "http://www.xiaoxiongbizhi.com/wallpapers/__85/4/2/422md4h0l.jpg",
    "http://pic.pp3.cn/uploads//allimg/111116/110213Nb-0.jpg",
    "http://pic.pp3.cn/uploads//allimg/111116/1102135554-1.jpg",
    "http://pic.pp3.cn/uploads//allimg/111116/11021321R-4.jpg",
    "http://jsdx1.downg.com//201602/langdunv_7.3_DownG.com.rar",
    "http://big.236.xdowns.com/g/%CE%D2%B5%C4%CA%C0%BD%E7.rar",
    "http://zjdx.downg.com//201602/xiaoqReader2.10.0.159_DownG.com.rar",
]

let downloadManager = DownloadManager(dir: "TTDownload")

class DownloadListViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let rightItem = UIBarButtonItem(title: "finished", style: .Plain, target: self, action: "finished")
        self.navigationItem.rightBarButtonItem = rightItem
        
        let btn = UIButton(type: .System)
        btn.setTitle("++AddTask", forState: UIControlState.Normal)
        btn.addTarget(self, action: "Add", forControlEvents: .TouchUpInside)
        self.navigationItem.titleView = btn
        
        self.title = "下载列表"
        
        self.tableView.registerNib(UINib(nibName: "DownloadCellTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.rowHeight = 58
        self.tableView.estimatedRowHeight = 58.0
        
        downloadManager.downloadFinied = { [weak self] t  in
            self?.tableView.reloadData()
        }
        
        downloadManager.downloadProgress = { [weak self] (t,index) in
            self?.tableView.reloadData()
        }
        
        downloadManager.downloadError = { [weak self] t  in
             self?.tableView.reloadData()
        }
        downloadManager.downloadAddUnfinishTask = { [weak self] t in
            self?.tableView.reloadData()
        }
    }

    var addIndex = 0
    
    func Add(){
        let index = self.addIndex % urlStrs.count
        let urlStr = urlStrs[index]
        if let _ = downloadManager.newTask(urlStr){
            self.tableView.reloadData()
        }
        self.addIndex++
    }
    
    func finished(){
        let vc = FinishedDownloadTableViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadManager.taskList.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let task = downloadManager.taskList[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("cell",forIndexPath: indexPath) as! DownloadCellTableViewCell
        cell.fileName.text = task.fileName
        cell.progress.text = String(format: "%.0f", task.progress*100) + "%"

        cell.speed.text = task.speedString + "/s"
        
        //state
        var stateStr = "暂停"
        if task.state == .failed {
            stateStr = "失败"
        }
        if task.state == .downloading{
            stateStr = "下载中"
        }
        if task.state == .paused{
            stateStr = "暂停"
        }
        cell.state.text = stateStr
        
        var  curSizeStr = "未知文件大小"
        if task.recvedSize > 0 {
            
            curSizeStr = task.recvedSizeString + " / " + task.fileSizeString
        }
        cell.cureentSize.text = curSizeStr
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let task = downloadManager.taskByIndex(indexPath.row){
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.setSelected(false, animated: true)
            
            downloadManager.stopOrStartTaskByURLStr(task.urlStr)

        }
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            
            if let task = downloadManager.taskByIndex(indexPath.row){
            downloadManager.deleteTask(task)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            }
        }
    }

}


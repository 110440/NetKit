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

//let downloadManager = DownloadManager(dir: "TTDownload")

class DownloadListViewController: UITableViewController ,UIAlertViewDelegate {

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
        
        BigDownloader.sharedInstance.taskCompletionHander = { [weak self] urlStrs  in
            self?.tableView.reloadData()
        }
        
        BigDownloader.sharedInstance.taskProgressHander = { [weak self] urlStrs  in
            self?.tableView.reloadData()
        }
        
        BigDownloader.sharedInstance.taskFailedHaner = { [weak self] (urlStr,error ) in
            var i = 0
            for item in BigDownloader.sharedInstance.downloadItemList{
                if item.urlStr == urlStr{
                   break
                }
                i++
            }
            if let cell = self?.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)){
                (cell as? DownloadCellTableViewCell)?.state.text = "下载错误"
                cell.contentView.backgroundColor = UIColor.redColor()
            }
            print(error)
        }
  
    }

    var addIndex = 0
    
    func Add(){
        let index = self.addIndex % urlStrs.count
        let urlStr = urlStrs[index]
        BigDownloader.sharedInstance.startDownloadTask(urlStr)
        self.tableView.reloadData()
        self.addIndex++
    }
    
    
    func finished(){
        let vc = FinishedDownloadTableViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    
    func Input(){
        
        let alert = UIAlertView(title: "输入url", message: "", delegate: self, cancelButtonTitle: "OK ")
        alert.alertViewStyle = .PlainTextInput
        alert.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        let text = alertView.textFieldAtIndex(0)?.text
        if text != nil{
            BigDownloader.sharedInstance.startDownloadTask(text!)
            self.tableView.reloadData()
            
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BigDownloader.sharedInstance.downloadItemList.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let row  = indexPath.row
        let task = BigDownloader.sharedInstance.downloadItemList[row]
        let cell = tableView.dequeueReusableCellWithIdentifier("cell",forIndexPath: indexPath) as! DownloadCellTableViewCell
        cell.fileName.text = task.name
        cell.progress.text = task.progressString

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
        
        let item = BigDownloader.sharedInstance.downloadItemList[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.setSelected(false, animated: true)
        
        if item.state == .downloading {
            BigDownloader.sharedInstance.pausedTaskByURLStr(item.urlStr)
        }else{
            BigDownloader.sharedInstance.startDownloadTask(item.urlStr)
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
            let item = BigDownloader.sharedInstance.downloadItemList[indexPath.row]
            BigDownloader.sharedInstance.deleteItemByURLStr(item.urlStr)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
        }
    }

}


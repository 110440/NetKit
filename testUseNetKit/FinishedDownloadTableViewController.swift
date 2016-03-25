//
//  FinishedDownloadTableViewController.swift
//  DownLoader
//
//  Created by tanson on 16/3/8.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import NetKit

class FinishedDownloadTableViewController: UITableViewController {

    var fileList:[DownloadFinishedFile]?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.title = "下载完成"
        self.tableView.registerClass(UITableViewCell.self , forCellReuseIdentifier: "cell")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.fileList = Downloader.instance.getDownloadFiniedList()
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.fileList?.count ?? 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        let file = self.fileList![indexPath.row]
        cell.textLabel?.text = file.fileName
        
        return cell
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let file = self.fileList?[indexPath.row] {
            if file.fileName.hasSuffix(".jpg") || file.fileName.hasSuffix(".png"){
                let vc = ShowImageViewController(nibName: "ShowImageViewController", bundle: nil)
                let image = UIImage(contentsOfFile: file.filePath)
                vc.img = image
                let nav = UINavigationController(rootViewController: vc)
                self.presentViewController(nav, animated: true, completion: { () -> Void in
                    
                })
            }else{
                
                let sizeStr = DownloadUtil.getFileSizeStrByPath(file.filePath)
                let alert = UIAlertView(title: "文件大小", message: sizeStr, delegate: nil, cancelButtonTitle: "OK ")
                alert.show()
            }
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
            
            Downloader.instance.deleteFinishedFile( self.fileList![indexPath.row].fileName )
            self.fileList?.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
        }
    }


    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

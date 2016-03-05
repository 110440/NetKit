//
//  ViewController.swift
//  testUseNetKit
//
//  Created by tanson on 16/2/1.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit


class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
   
        self.title = "主页"
        self.automaticallyAdjustsScrollViewInsets = true
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        if indexPath.row == 0{
            cell.textLabel?.text = "NetKit"
        }else{
            cell.textLabel?.text = "DownloadManager"
        }
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            let vc = TestNetKit()
            self.navigationController?.pushViewController(vc, animated: true)
        }else{
            let vc = TestDownload()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}


//
//  ShowImageViewController.swift
//  DownLoader
//
//  Created by tanson on 16/3/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class ShowImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var img:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "图片"
        // Do any additional setup after loading the view.
        let barItem = UIBarButtonItem(title: "关闭", style: .Plain, target: self, action: "close")
        self.navigationItem.leftBarButtonItem = barItem
        
        self.imageView.image = self.img
    }

    func close(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

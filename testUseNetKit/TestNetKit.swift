//
//  TestNetKit.swift
//  testUseNetKit
//
//  Created by tanson on 16/3/4.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import UIKit
import NetKit
import Alamofire

class TestNetKit:UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "NetKit"
        self.view.backgroundColor = UIColor.lightGrayColor()
        
        self.test()
    }
    
    func test(){
        
        
        let key = "8dd33c1df29d46e3909f174f1f543c5f"
        let city = "湛江"
        
        // config netKit
        NetKitGloble.willReturnObjectBlock = { json -> (JSON?,NSError?) in
            let error_code = json["error_code"].intValue
            if error_code != 0 {
                let e = NSError(domain:json["reason"].stringValue, code: error_code, userInfo: nil )
                return (nil,e)
            }
            return (json["result"],nil)
        }
        NetKitGloble.addingParameters["key"] = key
        
        let req = Alamofire.request(testAPI.GetWeather(city)).responseObject { (response, object:ResultObj?, error) -> () in
            
            if error?.code == NSURLErrorCancelled{
                print("取消")
            }
            
            if let object = object{
                dump(object)
            }
            
        }
        req.cancel()
        
    }
}
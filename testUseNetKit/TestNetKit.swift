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
        
        
        let key = "f34GZCoqOBSK69QYYnqdg5xz"
        let city = "湛江"
        
        // config netKit
        NetKitGloble.willReturnObjectBlock = { json -> (JSON?,NSError?) in
            let error_code = json["error"].intValue
            if error_code != 0 {
                let e = NSError(domain:json["status"].stringValue, code: error_code, userInfo: nil )
                return (nil,e)
            }
            return (json["results"],nil)
        }
        NetKitGloble.addingParameters["ak"] = key
        NetKitGloble.addingParameters["output"] = "json"
        NetKitGloble.addingParameters["mcode"] = "com.tanson.NetKit.testUseNetKit"
        
        Alamofire.request(testAPI.GetWeather(city)).responseArray { (response, object:[TestModel]?, error) -> () in
            if let object = object{
                dump(object)
            }
        }
        
    }
}
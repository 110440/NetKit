//
//  testAPI.swift
//  UseNetwork
//
//  Created by tanson on 16/1/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import NetKit
import Alamofire

enum testAPI:NetKitTarget{
    case GetWeather(String)
}

extension testAPI {
    
    var baseURLString:String { return "http://api.map.baidu.com/telematics/v3/" }
    
    var path: String {
        switch self {
        case .GetWeather:
            return "/weather"
        }
    }
    var method:NetKitMethod {
        return NetKitMethod.GET
    }
    var parameters: [String: AnyObject]? {
        switch self{
        case .GetWeather(let city):
            return ["location" :city]
        }
    }

}


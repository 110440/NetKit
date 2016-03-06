//
//  NetworkKitProtocol.swift
//  UseNetwork
//
//  Created by tanson on 16/1/31.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import Alamofire


// MARK:- TSwiftyJSONAble
public protocol TSwiftyJSONAble {
    init?(json:JSON)
}

// MARK:- toDictionary protocol
public protocol TToDictionaryAble{
    func toDictionary()->Dictionary<String,AnyObject>
}

//MARK:- NetKitTarget
public protocol NetKitTarget:URLRequestConvertible{
    var baseURLString:String{get}
    var path:String{get}
    var method:NetKitMethod{get}
    var parameters:[String: AnyObject]?{get}
    
    // extension
    var URLRequest: NSMutableURLRequest{get}
    var parameterEncoding:Alamofire.ParameterEncoding{get}
}

public extension NetKitTarget{
    
    public var parameterEncoding:Alamofire.ParameterEncoding{
        return Alamofire.ParameterEncoding.URL
    }
    
    public var URLRequest: NSMutableURLRequest {
        
        let URLString = self.baseURLString + path
        let URLRequest = NSMutableURLRequest(URL:NSURL(string:URLString)!)
        let encoding = self.parameterEncoding
        URLRequest.HTTPMethod = self.method.rawValue
        
        // adding httpHeader
        URLRequest.allHTTPHeaderFields = NetKitGloble.addingHTTPHeaderFields
        
        // parameters
        var parameters = self.parameters ?? [String: AnyObject]()
        
        for (key,value) in NetKitGloble.addingParameters{
            parameters[key] = value
        }
        
        return encoding.encode(URLRequest, parameters: parameters ).0
    }
}

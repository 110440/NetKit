//
//  NetKit.swift
//  NetKit
//
//  Created by tanson on 16/2/2.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

// MARK:- NetKitMethod
public enum NetKitMethod: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}


// MARK:- NetKit Globle config
public class NetKitGloble{
    public static var addingParameters = [String:AnyObject]()
    public static var addingHTTPHeaderFields = [String:String]()
    public static var willReturnObjectBlock:((json:JSON) -> (JSON?,NSError?))?
}

// MARK: toDictionary 使用的, 把 数组 按类型转成 元素为 String,Int,Float,Double,Bool,Dictionary
// 暂时不支持多维数组
public func TTparseObjArrayToAnyObjArray(obj:Array<AnyObject>?)-> Array<AnyObject>?{
    
    guard let obj = obj else { return nil }
    guard obj.count > 0 else { return nil }
    
    switch obj.first {
    case _ as String , _ as Int ,_ as Float , _ as Double , _ as Bool:
        return obj.flatMap{ $0 }
    case _ as TToDictionaryAble:
        return obj.flatMap{ ($0 as! TToDictionaryAble).toDictionary() }
    default:
        fatalError("==== toDictionary unkonw type ")
        break
    }
    return nil
}


//MARK:- extension base type to comf TSwiftyJSONAble
extension String:TSwiftyJSONAble{
    public init?(json: JSON) {
        self = json.stringValue
    }
}

extension Int:TSwiftyJSONAble{
    public init?(json: JSON) {
        self = json.intValue
    }
}

extension Float:TSwiftyJSONAble{
    public init?(json: JSON) {
        self = json.floatValue
    }
}

extension Double:TSwiftyJSONAble{
    public init?(json: JSON) {
        self = json.doubleValue
    }
}

extension Bool:TSwiftyJSONAble{
    public init?(json: JSON) {
        self = json.boolValue
    }
}


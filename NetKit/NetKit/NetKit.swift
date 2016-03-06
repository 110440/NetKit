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

// MARK:- NetKit

public class NetKitGloble{
    public static var addingParameters = [String:AnyObject]()
    public static var addingHTTPHeaderFields = [String:String]()
    public static var willReturnObjectBlock:((json:JSON) -> (JSON?,NSError?))?
}

// MARK:- swiftyJSON extension : To swiftyJSONAble object
public extension JSON{
    
    func toObject<T:TSwiftyJSONAble>(objectType:T.Type)->T?{
        return objectType.init(json: self)
    }
    
    func toObjectArray<T:TSwiftyJSONAble>(objectType:T.Type)->[T]{
        return self.arrayValue
            .map({ objectType.init(json: $0) }) // Map to T
            .filter({ $0 != nil }) // Filter out failed objects
            .map({ $0! }) // Cast to non optionals array
    }
}

// MARK: toDictionary 使用的, 把 数组 按类型转成 AnyObject
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

// MARK:- URLEscapedString

public extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    var URLEscapedStringInGB18030:String{
        let string = CFURLCreateStringByAddingPercentEscapes(nil, (self as CFString) ,nil,(":/?#[]@!$&’()*+,;=" as CFString), UInt32( CFStringEncodings.GB_18030_2000.rawValue) )
        return string as String
    }
}

//MARK:- base type TSwiftyJSONAble
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


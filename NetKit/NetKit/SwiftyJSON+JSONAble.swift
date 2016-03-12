//
//  SwiftyJSON+JSONAble.swift
//  NetKit
//
//  Created by tanson on 16/3/12.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

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
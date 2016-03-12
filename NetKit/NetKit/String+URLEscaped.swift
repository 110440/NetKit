//
//  String+.swift
//  NetKit
//
//  Created by tanson on 16/3/12.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

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
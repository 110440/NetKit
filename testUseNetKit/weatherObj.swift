//
//  weatherObj.swift
//  UseNetwork
//
//  Created by tanson on 16/1/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import NetKit

class TestModel:TSwiftyJSONAble,TToDictionaryAble {
    
    class Weather_data:TSwiftyJSONAble,TToDictionaryAble {
        
        var wind:String?
        var date:String?
        var temperature:String?
        var weather:String?
        var nightPictureUrl:String?
        var dayPictureUrl:String?
        
        required init?(json:JSON) {
            self.wind = json["wind"].string
            self.date = json["date"].string
            self.temperature = json["temperature"].string
            self.weather = json["weather"].string
            self.nightPictureUrl = json["nightPictureUrl"].string
            self.dayPictureUrl = json["dayPictureUrl"].string
        }
        
        init(){ }
        
        func toDictionary()->Dictionary<String,AnyObject>{
            var dic = [String:AnyObject]()
            dic["wind"] = self.wind
            dic["date"] = self.date
            dic["temperature"] = self.temperature
            dic["weather"] = self.weather
            dic["nightPictureUrl"] = self.nightPictureUrl
            dic["dayPictureUrl"] = self.dayPictureUrl
            return dic
        }
        
    }
    
    class Index:TSwiftyJSONAble,TToDictionaryAble {
        
        var title:String?
        var des:String?
        var tipt:String?
        var zs:String?
        
        required init?(json:JSON) {
            self.title = json["title"].string
            self.des = json["des"].string
            self.tipt = json["tipt"].string
            self.zs = json["zs"].string
        }
        
        init(){ }
        
        func toDictionary()->Dictionary<String,AnyObject>{
            var dic = [String:AnyObject]()
            dic["title"] = self.title
            dic["des"] = self.des
            dic["tipt"] = self.tipt
            dic["zs"] = self.zs
            return dic
        }
        
    }
    
    var pm25:String?
    var weather_data:[Weather_data]?
    var currentCity:String?
    var index:[Index]?
    
    required init?(json:JSON) {
        self.pm25 = json["pm25"].string
        self.weather_data = json["weather_data"].toObjectArray(Weather_data)
        self.currentCity = json["currentCity"].string
        self.index = json["index"].toObjectArray(Index) 
    }
    
    init(){ }
    
    func toDictionary()->Dictionary<String,AnyObject>{
        var dic = [String:AnyObject]()
        dic["pm25"] = self.pm25 
        dic["weather_data"] = TTparseObjArrayToAnyObjArray(self.weather_data)
        dic["currentCity"] = self.currentCity 
        dic["index"] = TTparseObjArrayToAnyObjArray(self.index)
        return dic 
    }
    
}



//
//  weatherObj.swift
//  UseNetwork
//
//  Created by tanson on 16/1/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import NetKit

class weatherRet:TSwiftyJSONAble{
    
    var error_code:Int?
    var reason:String?
    var result:ResultObj?
    
    required init?(json: JSON) {
        self.error_code = json["error_code"].int
        self.reason = json["reason"].string
        self.result = json["result"].toObject(ResultObj)
    }
}
/*
class ResultObj:TSwiftyJSONAble {
    var sk:skObj?
    var today:Today?
    var future:[Future]?
    
    required init?(json: JSON) {
        self.sk = json["sk"].toObject(skObj)
        self.today = json["today"].toObject(Today)
        self.future = json["future"].toObjectArray(Future)
    }
}

class skObj:TSwiftyJSONAble {
    
    var temp:String?
    var wind_direction:String?
    var wind_strength:String?
    var humidity:String?
    var time:String?
    
    required init?(json: JSON) {
        self.temp = json["temp"].string
        self.wind_direction = json["wind_direction"].string
        self.wind_strength = json["wind_strength"].string
        self.humidity = json["humidity"].string
        self.time = json["time"].string
    }
}

class Today:TSwiftyJSONAble {
    
    var city:String?
    var date_y:String?
    var week:String?
    
    var temperature:String?
    var weather:String?
    
    required init?(json: JSON) {
        self.city = json["city"].string
        self.date_y = json["date_y"].string
        self.week = json["week"].string
        
    }
}

class Future:TSwiftyJSONAble {
    
    var temperature:String?
    var weather:String?

    
    required init?(json: JSON) {
        self.temperature = json["temperature"].string
        self.weather = json["weather"].string
        
    }
}
*/
class ResultObj:TSwiftyJSONAble,TToDictionaryAble {
    
    class Future:TSwiftyJSONAble,TToDictionaryAble {
        
        var fa:String?
        var weather:String?
        var date:String?
        var wind:String?
        var week:String?
        var fb:String?
        var temperature:String?
        
        required init?(json:JSON) {
            self.fa = json["fa"].string
            self.weather = json["weather"].string
            self.date = json["date"].string
            self.wind = json["wind"].string
            self.week = json["week"].string
            self.fb = json["fb"].string
            self.temperature = json["temperature"].string
        }
        
        init(){ }
        
        func toDictionary()->Dictionary<String,AnyObject>{
            var dic = [String:AnyObject]()
            dic["fa"] = self.fa
            dic["weather"] = self.weather
            dic["date"] = self.date
            dic["wind"] = self.wind
            dic["week"] = self.week
            dic["fb"] = self.fb
            dic["temperature"] = self.temperature
            return dic
        }
        
    }
    
    class Sk:TSwiftyJSONAble,TToDictionaryAble {
        
        var humidity:String?
        var temp:String?
        var wind_strength:String?
        var wind_direction:String?
        var time:String?
        
        required init?(json:JSON) {
            self.humidity = json["humidity"].string
            self.temp = json["temp"].string
            self.wind_strength = json["wind_strength"].string
            self.wind_direction = json["wind_direction"].string
            self.time = json["time"].string
        }
        
        init(){ }
        
        func toDictionary()->Dictionary<String,AnyObject>{
            var dic = [String:AnyObject]()
            dic["humidity"] = self.humidity
            dic["temp"] = self.temp
            dic["wind_strength"] = self.wind_strength
            dic["wind_direction"] = self.wind_direction
            dic["time"] = self.time
            return dic
        }
        
    }
    
    class Today:TSwiftyJSONAble,TToDictionaryAble {
        
        var city:String?
        var fa:String?
        var wind:String?
        var date_y:String?
        var drying_index:String?
        var wash_index:String?
        var weather:String?
        var uv_index:String?
        var comfort_index:String?
        var dressing_index:String?
        var week:String?
        var fb:String?
        var temperature:String?
        var dressing_advice:String?
        var exercise_index:String?
        var travel_index:String?
        
        required init?(json:JSON) {
            self.city = json["city"].string
            self.fa = json["fa"].string
            self.wind = json["wind"].string
            self.date_y = json["date_y"].string
            self.drying_index = json["drying_index"].string
            self.wash_index = json["wash_index"].string
            self.weather = json["weather"].string
            self.uv_index = json["uv_index"].string
            self.comfort_index = json["comfort_index"].string
            self.dressing_index = json["dressing_index"].string
            self.week = json["week"].string
            self.fb = json["fb"].string
            self.temperature = json["temperature"].string
            self.dressing_advice = json["dressing_advice"].string
            self.exercise_index = json["exercise_index"].string
            self.travel_index = json["travel_index"].string
        }
        
        init(){ }
        
        func toDictionary()->Dictionary<String,AnyObject>{
            var dic = [String:AnyObject]()
            dic["city"] = self.city
            dic["fa"] = self.fa
            dic["wind"] = self.wind
            dic["date_y"] = self.date_y
            dic["drying_index"] = self.drying_index
            dic["wash_index"] = self.wash_index
            dic["weather"] = self.weather
            dic["uv_index"] = self.uv_index
            dic["comfort_index"] = self.comfort_index 
            dic["dressing_index"] = self.dressing_index 
            dic["week"] = self.week 
            dic["fb"] = self.fb 
            dic["temperature"] = self.temperature 
            dic["dressing_advice"] = self.dressing_advice 
            dic["exercise_index"] = self.exercise_index 
            dic["travel_index"] = self.travel_index 
            return dic 
        }
        
    }
    
    var future:[Future]?
    var sk:Sk?
    var today:Today?
    
    required init?(json:JSON) {
        self.future = json["future"].toObjectArray(Future) 
        self.sk = json["sk"].toObject(Sk) 
        self.today = json["today"].toObject(Today) 
    }
    
    init(){ }
    
    func toDictionary()->Dictionary<String,AnyObject>{
        var dic = [String:AnyObject]()
        dic["future"] = TTparseObjArrayToAnyObjArray(self.future)
        dic["sk"] = self.sk?.toDictionary() 
        dic["today"] = self.today?.toDictionary() 
        return dic 
    }
    
}



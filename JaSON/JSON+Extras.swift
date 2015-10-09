
import Foundation

extension Float : JSONValueType {}
extension Double : JSONValueType {}
extension Bool: JSONValueType {}

public protocol JSONCollectionType {
    func jsonData() throws -> NSData
}

extension JSONCollectionType {
    public func jsonData() throws -> NSData {
        guard let jsonCollection = self as? AnyObject else {
            throw JSONError.TypeMismatchForKey("{\"rootObject\":null}")
        }
        return try NSJSONSerialization.dataWithJSONObject(jsonCollection, options: [])
    }
}

extension Dictionary : JSONCollectionType {}
extension Array : JSONCollectionType {}

public typealias JSONObjectArray = Array<JSONObject>


public extension Dictionary where Key: JSONKeyType {
    
    public static func JSONObjectWithData(data:NSData) throws -> [Key:Value] {
        let obj:Any = try NSJSONSerialization.JSONObjectWithData(data, options: [])
        return try self.JSONValue(obj)
    }
    
    static func JSONObjectArrayWithData(data:NSData) throws -> [JSONObject] {
        let object:AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
        guard let ra = object as? [JSONObject] else {
            throw JSONError.TypeMismatchForValue( object.dynamicType, self )
        }
        return ra
    }
    
}

//public extension Array where Element: JSONCollectionType {
//    public static func JSONObjectArrayWithData(data:NSData) throws -> [[String:AnyObject]] {
//        let object:AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
//        guard let ra = object as? JSONObjectArray else {
//            throw JSONError.TypeMismatchForValue( object.dynamicType, self )
//        }
//        return ra
//    }
//}

extension NSDate : JSONValueType {
    public static func JSONValue(object: Any) throws -> NSDate {
        if let dateString = object as? String,
            date = NSDate.fromISO8601String(dateString) {
                return date
        }
        throw JSONError.TypeMismatchForValue( object.dynamicType, self )
    }
}

public extension NSDate {
    static private let ISO8601MillisecondFormatter:NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        let tz = NSTimeZone(abbreviation:"GMT")
        formatter.timeZone = tz
        return formatter
        }()
    static private let ISO8601SecondFormatter:NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";
        let tz = NSTimeZone(abbreviation:"GMT")
        formatter.timeZone = tz
        return formatter
        }()
    
    static private let formatters = [ISO8601MillisecondFormatter,
                                    ISO8601SecondFormatter]
    
    static func fromISO8601String(dateString:String) -> NSDate? {
        for formatter in formatters {
            if let date = formatter.dateFromString(dateString) {
                return date
            }
        }
        return .None
    }
}

extension NSURL : JSONValueType {
    public static func JSONValue(object: Any) throws -> NSURL {
        if let urlString = object as? String,
            url = NSURL(string: urlString) {
                return url
        }
        throw JSONError.TypeMismatchForValue(object.dynamicType, self)
    }
}

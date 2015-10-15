
import Foundation

extension Float : JSONValueType {}
extension Double : JSONValueType {}
extension Bool: JSONValueType {}

public struct JSONParser {
    public static func JSONObjectWithData(data:NSData) throws -> JSONObject {
        let obj:Any = try NSJSONSerialization.JSONObjectWithData(data, options: [])
        return try JSONObject.JSONValue(obj)
    }
    
    public static func JSONObjectArrayWithData(data:NSData) throws -> [JSONObject] {
        let object:AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
        guard let ra = object as? [JSONObject] else {
            throw JSONError.TypeMismatchForValue(expectedType: [JSONObject].self, foundType: object.dynamicType)
        }
        return ra
    }
}

public protocol JSONCollectionType {
    func jsonData() throws -> NSData
}

extension JSONCollectionType {
    public func jsonData() throws -> NSData {
        guard let jsonCollection = self as? AnyObject else {
            throw JSONError.TypeMismatch(key:nil, expectedType: AnyObject.self, foundType: self.dynamicType) // shouldn't happen
        }
        return try NSJSONSerialization.dataWithJSONObject(jsonCollection, options: [])
    }
}

//public protocol JSONObjectConvertible : JSONValueType {
//    typealias ConvertibleType = Self
//    init(json:JSONObject) throws
//}
//
//extension JSONObjectConvertible {
//    public static func JSONValue(object: Any) throws -> ConvertibleType {
//        guard let json = object as? JSONObject else {
//            throw JSONError.TypeMismatchForValue(expectedType: JSONObject.self, foundType: object.dynamicType)
//        }
//        return try ConvertibleType(json: json)
//    }
//}

extension Dictionary : JSONCollectionType {}
extension Array : JSONCollectionType {}

public typealias JSONObjectArray = [JSONObject]


extension NSDate : JSONValueType {
    public static func JSONValue(object: Any) throws -> NSDate {
        if let dateString = object as? String,
            date = NSDate.fromISO8601String(dateString) {
                return date
        }
        throw JSONError.TypeMismatchForValue(expectedType: String.self, foundType: object.dynamicType)
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
        throw JSONError.TypeMismatchForValue(expectedType: String.self, foundType: object.dynamicType)
    }
}

infix operator <| { associativity left precedence 150 }
infix operator <|? { associativity left precedence 150 }

public func <| <A: JSONValueType>(dictionary: JSONObject, key: String) throws -> A {
    return try dictionary.JSONValueForKey(key)
}

public func <|? <A: JSONValueType>(dictionary: [String: AnyObject], key: String) throws -> A? {
    return try dictionary.JSONOptionalForKey(key)
}

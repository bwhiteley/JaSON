// MARK: - Keys

import Foundation

public protocol JSONKeyType {
    var JSONKey: String { get }
}

extension String: JSONKeyType {
    public var JSONKey: String {
        return self
    }
}

// MARK: - Values

public protocol JSONValueType {
    typealias JSONItem = Self
    
    /** 
    * Convert a native JSON type into a conforming type.
    * See NSURL for an example. If the native type provided is not compatible, 
    * throw a JSONError.TypeMismatchForValue.
    */
    static func JSONValue(object: Any) throws -> JSONItem
}

extension JSONValueType {
    public static func JSONValue(object: Any) throws -> JSONItem {
        guard let value = object as? JSONItem else {
            throw JSONError.TypeMismatchForValue(expectedType: JSONItem.self, foundType: object.dynamicType)
        }
        return value
    }
}

extension Int : JSONValueType {
}

extension String : JSONValueType {
}

extension Array where Element : JSONValueType {
    public static func JSONValue(object: Any) throws -> [Element] {
        if let object = object as? [Element] {
            return object
        }
        throw JSONError.TypeMismatch(key: nil, expectedType: self, foundType: object.dynamicType)
    }
}

extension Dictionary : JSONValueType {
    public static func JSONValue(object: Any) throws -> Dictionary<Key, Value> {
        if let object = object as? Dictionary<Key, Value> {
            return object
        }
        throw JSONError.TypeMismatchForValue(expectedType: self, foundType: object.dynamicType)
    }
}

// MARK: - The Parsing

public enum JSONError : ErrorType, CustomStringConvertible {
    case KeyNotFound(String)
    case TypeMismatch(key:String?, expectedType:Any, foundType:Any)
    case NullValueForKey(String)
    case TypeMismatchForValue(expectedType:Any, foundType:Any)
    
    public var description: String {
        switch self {
        case let .KeyNotFound(key):
            return "JSON Error. Expected value for key: \(key)"
        case let .NullValueForKey(key):
            return "JSON Error. Null value for key: \(key)"
        case let .TypeMismatch(key, expectedType, foundType):
            return "JSON Error. Expected \(expectedType) for key \(key), found \(foundType)"
        case let .TypeMismatchForValue(expectedType, foundType):
            return "JSON Error. Expected \(expectedType), found \(foundType)"
        }
    }
}

extension Dictionary where Key: JSONKeyType {
    private func objectForKey(key: Key) throws -> Any {
        let pathComponents = key.JSONKey.characters.split(".").map(String.init)
        var accumulator: Any = self
        
        for component in pathComponents {
            if let componentData = accumulator as? [Key: Value] {
                if let key = component as? Key, value = componentData[ key ] {
                    accumulator = value
                    continue
                }
            }
            
            throw JSONError.KeyNotFound(key.JSONKey)
        }
        
        // Treat "null" as missing. 
        // This differs from jarsen's 
        if let _ = accumulator as? NSNull {
            throw JSONError.NullValueForKey(key.JSONKey)
        }
        
        return accumulator
    }
    
    public func JSONValueForKey<A: JSONValueType>(key: Key) throws -> A {
        let accumulator = try objectForKey(key)
        do {
            let jsonValue = try A.JSONValue(accumulator)
            guard let result = jsonValue as? A else {
                throw JSONError.TypeMismatch(key:key.JSONKey, expectedType:A.self, foundType:jsonValue.dynamicType)
            }
            return result
        }
        catch let JSONError.TypeMismatchForValue(expectedType: expectedType, foundType: foundType) {
            throw JSONError.TypeMismatch(key:key.JSONKey, expectedType: expectedType, foundType: foundType)
        }
    }
    
    public func JSONValueForKey<A: JSONValueType>(key: Key) throws -> [A] {
        let accumulator = try objectForKey(key)
        return try Array<A>.JSONValue(accumulator)
    }
    
    public func JSONOptionalForKey<A: JSONValueType>(key: Key) throws -> A? {
        do {
            return try self.JSONValueForKey(key) as A
        }
        catch JSONError.KeyNotFound {
            return nil
        }
        catch JSONError.NullValueForKey {
            return nil
        }
    }
    
    
}

public typealias JSONObject = Dictionary<String, AnyObject>


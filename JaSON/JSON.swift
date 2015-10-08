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

//public protocol JSONValueType {
//    static func JSONValue(object: Any) throws -> Self
//}

public protocol JSONValueType {
    typealias JSONItem = Self
    static func JSONValue(object: Any) throws -> JSONItem
}

extension JSONValueType {
    public static func JSONValue(object: Any) throws -> JSONItem {
        if let object = object as? JSONItem {
            return object
        }
        throw JSONError.TypeMismatch
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
        throw JSONError.TypeMismatch
    }
}

extension Dictionary : JSONValueType {
    public static func JSONValue(object: Any) throws -> Dictionary<Key, Value> {
        if let object = object as? Dictionary<Key, Value> {
            return object
        }
        throw JSONError.TypeMismatch
    }
}

// MARK: - The Parsing

public enum JSONError: ErrorType {
    case NoValueForKey(String)
    case TypeMismatch
}

extension Dictionary where Key: JSONKeyType {
    private func objectForKey(key: Key) throws -> Any {
        let pathComponents = key.JSONKey.characters.split(".").map(String.init)
        var accumulator: Any = self
        
        for component in pathComponents {
            if let componentData = accumulator as? [Key: Value] {
                if let value = componentData[ component as! Key ] {
                    accumulator = value
                    continue
                }
            }
            
            throw JSONError.NoValueForKey(key.JSONKey)
        }
        
        // Treat "null" as missing. 
        // This differs from jarsen's 
        if let _ = accumulator as? NSNull {
            throw JSONError.NoValueForKey(key.JSONKey)
        }
        
        return accumulator
    }
    
    public func JSONValueForKey<A: JSONValueType>(key: Key) throws -> A {
        let accumulator = try objectForKey(key)
        guard let result = try A.JSONValue(accumulator) as? A else {
            throw JSONError.TypeMismatch
        }
        return result
    }
    
    public func JSONValueForKey<A: JSONValueType>(key: Key) throws -> [A] {
        let accumulator = try objectForKey(key)
        return try Array<A>.JSONValue(accumulator)
    }
    
    public func JSONOptionalForKey<A: JSONValueType>(key: Key) throws -> A? {
        do {
            return try self.JSONValueForKey(key) as A
        }
        catch JSONError.NoValueForKey {
            return nil
        }
        catch {
            throw JSONError.TypeMismatch
        }
    }
    
    
}

public typealias JSONObject = Dictionary<String, AnyObject>


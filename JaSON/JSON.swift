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
        throw JSONError.TypeMismatchForValue( object.dynamicType, JSONItem.self )
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
        throw JSONError.TypeMismatchForValue( object.dynamicType, self )
    }
}

extension Dictionary : JSONValueType {
    public static func JSONValue(object: Any) throws -> Dictionary<Key, Value> {
        if let object = object as? Dictionary<Key, Value> {
            return object
        }
        throw JSONError.TypeMismatchForValue( object.dynamicType, self )
    }
}

// MARK: - The Parsing

public enum JSONError: ErrorType, CustomStringConvertible
{
    case KeyNotFound( JSONKeyType ),
    NullValueForKey( JSONKeyType ),
    TypeMismatchForKey( JSONKeyType ),
    TypeMismatchForValue( Any, Any ),
    SerializationFailure( ErrorType )
    
    public var description: String
        {
            switch self
            {
            case let .KeyNotFound( key ):
                return "Key not found: \(key.JSONKey)"
            case let .NullValueForKey( key ):
                return "\"null\" value for key: \(key.JSONKey)"
            case let .TypeMismatchForKey( key ):
                return "Type mismatch for key: \(key.JSONKey)"
            case let .TypeMismatchForValue( value, expectedType ):
                return "Type mismatch. Found '\(value)' expecting '\(expectedType)'"
            case let .SerializationFailure( error ):
                return "Serialization failed with error: \(error)"
            }
    }
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
        guard let result = try A.JSONValue(accumulator) as? A else {
            throw JSONError.TypeMismatchForKey( key )
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
        catch JSONError.KeyNotFound {
            return nil
        }
        catch JSONError.NullValueForKey {
            return nil
        }
        catch {
            throw JSONError.TypeMismatchForKey(key)
        }
    }
    
    
}

public typealias JSONObject = Dictionary<String, AnyObject>



import XCTest
@testable import JaSON

class JaSONTests: XCTestCase {
    
    let object: JSONObject = ["foo" : (2 as NSNumber), "str": "Hello, World!", "array" : [1,2,3,4,7], "object": ["foo" : (3 as NSNumber), "str": "Hello, World!"], "url":"http://apple.com", "date":"2015-10-07T15:04:46Z", "junk":"garbage", "urls":["http://apple.com", "http://github.com"]]

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasics() {
        self.measureBlock {
            let str: String = try! self.object.JSONValueForKey("str")
            XCTAssertEqual(str, "Hello, World!")
            //    var foo1: String = try object.JSONValueForKey("foo")
            let foo2: Int = try! self.object.JSONValueForKey("foo")
            XCTAssertEqual(foo2, 2)
            let foo3: Int? = try! self.object.JSONValueForKey("foo")
            XCTAssertEqual(foo3, 2)
            let foo4: Int? = try! self.object.JSONValueForKey("bar")
            XCTAssertEqual(foo4, .None)
            let arr: [Int] = try! self.object.JSONValueForKey("array")
            XCTAssert(arr.count == 5)
            let obj: JSONObject = try! self.object.JSONValueForKey("object")
            XCTAssert(obj.count == 2)
            let innerfoo: Int = try! obj.JSONValueForKey("foo")
            XCTAssertEqual(innerfoo, 3)
            let innerfoo2: Int = try! self.object.JSONValueForKey("object.foo")
            XCTAssertEqual(innerfoo2, 3)
            let url:NSURL = try! self.object.JSONValueForKey("url")
            XCTAssertEqual(url.host, "apple.com")
            let _:NSDate = try! self.object.JSONValueForKey("date")
            let date:NSDate? = try! self.object.JSONValueForKey("date")
            XCTAssert(date != .None)
            
            let expectation = self.expectationWithDescription("error")
            do {
                let _:NSDate? = try self.object.JSONValueForKey("junk")
            }
            catch {
                let jsonError = error as! JSONError
                expectation.fulfill()
                guard case JSONError.TypeMismatch = jsonError else {
                    XCTFail("shouldn't get here")
                    return
                }
            }
            
            let urls:[NSURL] = try! self.object.JSONValueForKey("urls")
            XCTAssertEqual(urls.first!.host, "apple.com")
            
            self.waitForExpectationsWithTimeout(1, handler: nil)
        }
        
    
    }
    
    func testOptionals() {
        var str:String = try! object <| "str"
        XCTAssertEqual(str, "Hello, World!")
        
        var optStr:String? = try! object <| "str"
        XCTAssertEqual(optStr, "Hello, World!")
        
        optStr = try! object <| "not found"
        XCTAssertEqual(optStr, .None)
        
        let ra:[Int] = try! object <| "array"
        XCTAssertEqual(ra[0], 1)
        
        var ora:[Int]? = try! object <| "array"
        XCTAssertEqual(ora![0], 1)

        ora = try! object <| "no key"
        XCTAssertNil(ora)

        let ex = self.expectationWithDescription("not found")
        do {
            str = try object <| "not found"
        }
        catch {
            if case JSONError.KeyNotFound = error {
                ex.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testErrors() {
        var expectation = self.expectationWithDescription("not found")
        let str: String = try! self.object.JSONValueForKey("str")
        XCTAssertEqual(str, "Hello, World!")
        do {
            let _:Int = try object.JSONValueForKey("no key")
        }
        catch {
            if case JSONError.KeyNotFound = error {
                expectation.fulfill()
            }
        }
        
        expectation = self.expectationWithDescription("key mismatch")
        do {
            let _:Int = try object.JSONValueForKey("str")
        }
        catch {
            if case JSONError.TypeMismatch = error {
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testDicionary() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("TestDictionary", ofType: "json")!
        var data = NSData(contentsOfFile: path)!
        var json:JSONObject = try! JSONParser.JSONObjectWithData(data)
        let url:NSURL = try! json.JSONValueForKey("meta.next")
        XCTAssertEqual(url.host, "apple.com")
        var people:[JSONObject] = try! json.JSONValueForKey("list")
        var person = people[0]
        let city:String = try! person.JSONValueForKey("address.city")
        XCTAssertEqual(city, "Cupertino")
        
        data = try! json.jsonData()
        
        json = try! JSONParser.JSONObjectWithData(data)
        people = try! json.JSONValueForKey("list")
        person = people[1]
        let dead = try! !person.JSONValueForKey("living")
        XCTAssertTrue(dead)
    }
    
    func testSimpleArray() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("TestSimpleArray", ofType: "json")!
        var data = NSData(contentsOfFile: path)!
        var ra = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as! [AnyObject]
        XCTAssertEqual(ra.first as? Int, 1)
        XCTAssertEqual(ra.last as? String, "home")
        
        data = try! ra.jsonData()
        ra = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as! [AnyObject]
        XCTAssertEqual(ra.first as? Int, 1)
        XCTAssertEqual(ra.last as? String, "home")
    }
    
    func testObjectArray() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("TestObjectArray", ofType: "json")!
        var data = NSData(contentsOfFile: path)!
        var ra:[JSONObject] = try! JSONParser.JSONObjectArrayWithData(data)
        
        var obj:JSONObject = ra[0]
        XCTAssertEqual(try! obj.JSONValueForKey("n") as Int, 1)
        XCTAssertEqual(try! obj.JSONValueForKey("str") as String, "hello")
        
        data = try! ra.jsonData()
        
        ra = try! JSONParser.JSONObjectArrayWithData(data)
        obj = ra[1]
        XCTAssertEqual(try! obj.JSONValueForKey("str") as String, "world")
    }
    
    func testNested() {
        let dict = ["type": "connected",
                "payload": [
                    "team": [
                        "id": "teamId",
                        "name": "teamName"
                    ]
                ]
            ]
        
        let teamId:String = try! dict.JSONValueForKey("payload.team.id")
        XCTAssertEqual(teamId, "teamId")
    }
    
    func testCustomObjects() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("People", ofType: "json")!
        let data = NSData(contentsOfFile: path)!
        let obj = try! JSONParser.JSONObjectWithData(data)
        let people:[Person] = try! obj.JSONValueForKey("people")
        let person:Person = try! obj.JSONValueForKey("person")
        XCTAssertEqual(people.first!.firstName, "Jason")
        XCTAssertEqual(person.firstName, "Jason")
        XCTAssertEqual(person.score, 42)
        XCTAssertEqual(people.last!.address!.city, "Cupertino")
    }
    
    enum MyEnum:String, JSONEnumType {
        case One
        case Two
        case Three
        
    }
    
    enum MyIntEnum:Int, JSONEnumType {
        case One = 1
        case Two = 2
    }
    

    func testEnum() {
        let json = ["one":"One", "two":"Two", "three":"Three", "four":"Junk", "iOne":NSNumber(integer: 1), "iTwo":NSNumber(integer: 2)]
        let one:MyEnum = try! json.JSONValueForKey("one")
        XCTAssertEqual(one, MyEnum.One)
        let two:MyEnum = try! json.JSONValueForKey("two")
        XCTAssertEqual(two, MyEnum.Two)
        
        let nope:MyEnum? = try! json.JSONValueForKey("junk")
        XCTAssertEqual(nope, .None)
        
        let expectation = expectationWithDescription("enum test")
        do {
            let _:MyEnum = try json.JSONValueForKey("four")
        }
        catch {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
        
        let iOne:MyIntEnum = try! json.JSONValueForKey("iOne")
        XCTAssertEqual(iOne, MyIntEnum.One)
        
    }
}

struct Address: JSONObjectConvertible {
    let street:String
    let city:String
    init(json: JSONObject) throws {
        street = try json.JSONValueForKey("street")
        city = try json.JSONValueForKey("city")
    }
}

struct Person: JSONObjectConvertible {
    let firstName:String
    let lastName:String
    let score:Int
    let address:Address?
    init(json: JSONObject) throws {
        firstName = try json.JSONValueForKey("first")
        lastName = try json.JSONValueForKey("last")
        score = try json.JSONValueForKey("score")
        address = try json.JSONValueForKey("address")
    }
}





import XCTest
@testable import JaSON

class JaSONTests: XCTestCase {
    
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
            let object: JSONObject = ["foo" : (2 as NSNumber), "str": "Hello, World!", "array" : [1,2,3,4,7], "object": ["foo" : (3 as NSNumber), "str": "Hello, World!"], "url":"http://apple.com", "date":"2015-10-07T15:04:46Z", "junk":"garbage"]
            let str: String = try! object.JSONValueForKey("str")
            XCTAssertEqual(str, "Hello, World!")
            //    var foo1: String = try object.JSONValueForKey("foo")
            let foo2: Int = try! object.JSONValueForKey("foo")
            XCTAssertEqual(foo2, 2)
            let foo3: Int? = try! object.JSONOptionalForKey("foo")
            XCTAssertEqual(foo3, 2)
            let foo4: Int? = try! object.JSONOptionalForKey("bar")
            XCTAssertEqual(foo4, .None)
            let arr: [Int] = try! object.JSONValueForKey("array")
            XCTAssert(arr.count == 5)
            let obj: JSONObject = try! object.JSONValueForKey("object")
            XCTAssert(obj.count == 2)
            let innerfoo: Int = try! obj.JSONValueForKey("foo")
            XCTAssertEqual(innerfoo, 3)
            let innerfoo2: Int = try! object.JSONValueForKey("object.foo")
            XCTAssertEqual(innerfoo2, 3)
            let url:NSURL = try! object.JSONValueForKey("url")
            XCTAssertEqual(url.host, "apple.com")
            let _:NSDate = try! object.JSONValueForKey("date")
            let date:NSDate? = try! object.JSONOptionalForKey("date")
            XCTAssert(date != .None)
            do {
                let _:NSDate? = try object.JSONOptionalForKey("junk")
                XCTFail("shouldn't get here")
            }
            catch {
                let jsonError = error as! JSONError
                guard case JSONError.TypeMismatch = jsonError else {
                    XCTFail("shouldn't get here")
                    return
                }
            }
        }
    
    }
    
    
    
}




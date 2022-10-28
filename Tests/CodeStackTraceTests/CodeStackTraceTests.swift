import XCTest
@testable import CodeStackTrace

class CodeStackTraceTests: XCTestCase {
    
    enum CodeError: Error {
        case someError(stackTrace: CodeStackTrace)
    }
    func _testFunctionTwo(_ stackTrace: CodeStackTrace) throws {
        throw CodeError.someError(stackTrace: stackTrace.stacking())
    }
    
    func _testFunctionOne(_ stackTrace: CodeStackTrace) throws {
        try _testFunctionTwo(stackTrace.stacking())
    }
    
    func testStackTrace() {
        do {
            try _testFunctionOne(CodeStackTrace())
            XCTFail("Expected '_testFunctionOne' to throw an exception")
        } catch CodeError.someError(stackTrace: let stackTrace) {
            guard stackTrace.count == 3 else {
                XCTFail("Expected 'stackTrace.count' to equal 3")
                return
            }
            XCTAssertEqual(stackTrace[0].functionName, "_testFunctionTwo")
            XCTAssertEqual(stackTrace[1].functionName, "_testFunctionOne")
            XCTAssertEqual(stackTrace[2].functionName, "testStackTrace")
            
            
        } catch {
            XCTFail("Caught unknown error:\n\(error)")
        }
    }


    static var allTests = [
        ("testStackTrace", testStackTrace),
    ]
}

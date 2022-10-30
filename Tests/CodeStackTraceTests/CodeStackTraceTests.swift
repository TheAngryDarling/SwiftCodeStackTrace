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
            
            #if _runtime(_ObjC)
            // on mac main thread runs as user interactive
            let expectedQOS: QualityOfService = .userInteractive
            #else
            // in open swift main thread runs as default
            let expectedQOS: QualityOfService = .default
            #endif
            
            #if !_runtime(_ObjC) && !swift(>=4.1)
            let expectedThreadDescription: String? = nil
            #else
            let expectedThreadDescription: String? = "main"
            #endif
            
            
            XCTAssertEqual(stackTrace[0].threadDetails.descriptionName, expectedThreadDescription)
            XCTAssertEqual(stackTrace[1].threadDetails.descriptionName, expectedThreadDescription)
            XCTAssertEqual(stackTrace[2].threadDetails.descriptionName, expectedThreadDescription)
            
            XCTAssertEqual(stackTrace[0].threadDetails.qualityOfService, expectedQOS)
            XCTAssertEqual(stackTrace[1].threadDetails.qualityOfService, expectedQOS)
            XCTAssertEqual(stackTrace[2].threadDetails.qualityOfService, expectedQOS)
            
            #if _runtime(_ObjC) || swift(>=4.1)
            XCTAssertTrue(stackTrace[0].threadDetails.isMainThread)
            XCTAssertTrue(stackTrace[1].threadDetails.isMainThread)
            XCTAssertTrue(stackTrace[2].threadDetails.isMainThread)
            #endif
            
            
        } catch {
            XCTFail("Caught unknown error:\n\(error)")
        }
    }


    static var allTests = [
        ("testStackTrace", testStackTrace),
    ]
}

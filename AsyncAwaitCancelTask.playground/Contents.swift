import XCTest

final class Tests: XCTestCase {
    
    func test_startTask_cancelTask_instanceShouldBeDeallocated() throws {
        let testDelayExp = expectation(description: "wait for completion")
        weak var weakSpy: ProcessSpy?
        
        autoreleasepool {
            var spy: ProcessSpy? = ProcessSpy()
            weakSpy = spy
            
            let task = Task { [unowned spy] in
                return try await spy!.testAsyncFunction()
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2, execute: {
                print("cancel task")
                task.cancel()
                spy = nil
            })
        }
        
        // a little delay just to be sure....
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            testDelayExp.fulfill()
        })
        wait(for: [testDelayExp], timeout: 1.0)
        
        XCTAssertNil(weakSpy, "expected `weakSpy` to have been deallocated, but it's still around!")
    }
    
    private actor ProcessSpy {
        private var continuation: CheckedContinuation<Int, Error>?
        
        func testAsyncFunction() async throws -> Int {
            return try await withCheckedThrowingContinuation { continuation in
                print("async operation started")
                self.continuation = continuation
            }
        }
    }
}

Tests.defaultTestSuite.run()

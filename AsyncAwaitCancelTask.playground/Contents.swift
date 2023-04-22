import XCTest

final class Tests: XCTestCase {
    
    func test_startTask_cancelTask_instanceShouldBeDeallocated() throws {
        let asyncFunctionStartedExp = expectation(description: "wait for start of async function")
        let testDelayExp = expectation(description: "wait for completion")
        weak var weakSpy: ProcessSpy?
        
        autoreleasepool {
            var spy: ProcessSpy? = ProcessSpy()
            weakSpy = spy
            
            let task = Task { [unowned spy] in
                return try await spy!.testAsyncFunction()
            }
            
            spy?.onStarted = {
                task.cancel()
                asyncFunctionStartedExp.fulfill()
            }
            
            wait(for: [asyncFunctionStartedExp], timeout: 1.0)
            spy = nil
        }
        
        // a little delay just to be sure....
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            testDelayExp.fulfill()
        })
        wait(for: [testDelayExp], timeout: 1.0)
        
        XCTAssertNil(weakSpy, "expected `weakSpy` to have been deallocated, but it's still around!")
    }
    
    private class ProcessSpy {
        var onStarted: (() -> Void)?
        private var continuation: CheckedContinuation<Int, Error>?
        
        func testAsyncFunction() async throws -> Int {
            let onStoreContinuation: (CheckedContinuation<Int, Error>) -> Void = { [weak self] continuation in
                self?.continuation = continuation
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                onStoreContinuation(continuation)
                onStarted?()
            }
        }
    }
}

Tests.defaultTestSuite.run()

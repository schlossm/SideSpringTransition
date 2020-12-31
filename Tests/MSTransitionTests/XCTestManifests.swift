import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MSTransitionContainerViewTests.allTests),
    ]
}
#endif

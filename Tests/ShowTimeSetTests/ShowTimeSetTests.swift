import XCTest
@testable import ShowTimeSet

final class ShowTimeSetTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ShowTimeSet(monTimes: "", tueTimes: "", wedTimes: "", thuTimes: "", friTimes: "", satTimes: "", sunTimes: "", dateSpecificTimes: [""]).text, "Hello, World!")
    }
}

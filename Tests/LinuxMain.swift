import XCTest

import WebSocketChatTests

var tests = [XCTestCaseEntry]()
tests += WebSocketChatClientTests.allTests()
XCTMain(tests)

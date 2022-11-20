//
//  AccordTests.swift
//  AccordTests
//
//  Created by charlotte on 2022-11-20.
//

@testable
import Accord

import XCTest
import Combine

final class AccordTests: XCTestCase {

    var markdownCancellable: AnyCancellable?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMarkdownParser() async throws {
        let markdown = """
        **uwu**
        > orange
        >orange
        *apple*
        """
        let markdownParsed = try await Markdown.markAll(text: markdown, channelInfo: ("", "")).values.first(where: { _ in true })
        print(markdownParsed)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

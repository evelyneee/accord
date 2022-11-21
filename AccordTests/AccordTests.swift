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
import SwiftUI

final class AccordTests: XCTestCase {

    var markdownCancellable: AnyCancellable?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMarkdownParser() {
        // This is an example of a performance test case.
        measure {
            let sem = DispatchSemaphore(value: 0)
            Task.detached {
                let markdown = """
                **uwu**
                > orange
                >orange
                *apple*
                **uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu** **uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu** **uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu****uwu**
                > orange
                > orange
                > orange
                > orange
                > orange> orange
                *apple* *apple* *apple* *apple* *apple* *apple* *apple*
                """
                _ = try await Markdown.markAll(text: markdown, channelInfo: ("", "")).values.first(where: { _ in true })
                sem.signal()
            }
            sem.wait()
        }
    }
}

//
//  File.swift
//  
//
//  Created by Rozeri Dilar on 19.06.2023.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Potential memory leak.", file: file, line: line)
        }
    }
}

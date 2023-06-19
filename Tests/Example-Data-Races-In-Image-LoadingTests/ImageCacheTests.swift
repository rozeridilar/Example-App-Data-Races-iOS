import XCTest
@testable import Example_Data_Races_In_Image_Loading

// MARK: - Threads

extension ImageCacheTests {

    func testConcurrentLoads() {
        let sut = self.createSut()
        let imageItem = anImageItem()

        let expectation = XCTestExpectation(description: #function)
        let numberOfRequests = 5
        let dispatchGroup = DispatchGroup()

        for _ in 0..<numberOfRequests {
            dispatchGroup.enter()
            sut.load(url: imageItem.url as NSURL, item: imageItem) { [weak self] (_, _) in
                guard self != nil else { return }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}

// MARK: - Helpers

final class ImageCacheTests: XCTestCase {

    func createSut(withDelay delay: TimeInterval = 0, file: StaticString = #filePath, line: UInt = #line) -> ImageCache {
        let imageData = try! Data(contentsOf: anImageItem().url)
        let response = HTTPURLResponse(url: anImageItem().url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let urlSession = aURLSession(response: (imageData, response),delay: delay)

        let imageCache = ImageCache(session: urlSession)

        trackForMemoryLeaks(imageCache, file: file, line: line)
        trackForMemoryLeaks(urlSession, file: file, line: line)

        return imageCache
    }
}

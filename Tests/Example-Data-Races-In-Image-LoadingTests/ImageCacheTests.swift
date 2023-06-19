import XCTest
@testable import Example_Data_Races_In_Image_Loading

// MARK: - Loading Image

extension ImageCacheTests {

    func testLoadImage() {
        let sut = createSut()
        let imageItem = anImageItem()

        let expectation = XCTestExpectation(description: #function)

        sut.load(url: imageItem.url as NSURL, item: imageItem) { [weak self] (fetchedItem, image) in
            guard self != nil else { return }

            if let image = image, image != fetchedItem.image {
                let cachedImage = sut.image(url: imageItem.url as NSURL)
                XCTAssertNotNil(cachedImage)
                XCTAssertEqual(cachedImage, image)

                XCTAssertTrue(Thread.isMainThread)

                expectation.fulfill()
            } else {
                XCTFail("Fetched image is either nil or equal to placeholder")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testCancelLoad_whenTaskIsNotFinished() {
        let sut = createSut()
        let imageItem = anImageItem()

        let expectation = XCTestExpectation(description: #function)
        expectation.isInverted = true

        // Only cancels the task that has not been finished.
        sut.load(url: imageItem.url as NSURL, item: imageItem) { [weak self] (_, image) in
            guard self != nil else { return }

            if image != nil {
                expectation.fulfill()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            sut.cancelLoad(imageItem.url as NSURL)
        }

        wait(for: [expectation], timeout: 1)
    }
}

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

    func testConcurrentLoads_withDifferentImageURLs() {
        let sut = createSut(withDelay: 0.1)
        let numberOfOperations = 10
        let imageURLs = (1...5).map { URL(string: "https://example.com/image\($0).jpg")! }
        let dispatchGroup = DispatchGroup()

        let expectation = XCTestExpectation(description: #function)
        expectation.expectedFulfillmentCount = numberOfOperations

        for _ in 0..<numberOfOperations {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let randomIndex = Int.random(in: 0..<imageURLs.count)
                let url = imageURLs[randomIndex] as NSURL

                sut.load(url: url, item: ImageItem(image: UIImage(), url: url as URL)) {  [weak self] (_, _) in
                    guard self != nil else { return }

                    expectation.fulfill()
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.wait(for: [expectation], timeout: 1)
        }
    }

    func testConcurrentLoads_withSameImageURLs() {
        let sut = createSut()
        let imageURL = URL(string: "https://example.com/image5.jpg")!
        let numberOfOperations = 10

        let expectation = XCTestExpectation(description: #function)
        expectation.expectedFulfillmentCount = numberOfOperations

        let dispatchGroup = DispatchGroup()
        for _ in 0..<numberOfOperations {
            dispatchGroup.enter()
            DispatchQueue.global().async {

                let item = ImageItem(image: UIImage(), url: imageURL)

                sut.load(url: imageURL as NSURL, item: item) {  [weak self] (_, _) in
                    guard self != nil else { return }
                    
                    expectation.fulfill()
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.wait(for: [expectation], timeout: 1)
        }
    }
}

// MARK: - Helpers

final class ImageCacheTests: XCTestCase {

    func createSut(withDelay delay: TimeInterval = 0, file: StaticString = #filePath, line: UInt = #line) -> ImageCache {
        let imageData = try! Data(contentsOf: anImageItem().url)
        let response = HTTPURLResponse(url: anImageItem().url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let urlSession = aURLSession(response: (imageData, response),delay: delay)

        let imageCache = ImageCache(session: urlSession)


        return imageCache
    }
}

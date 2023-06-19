//
//  URLProtocol+TestHelpers.swift
//  
//
//  Created by Rozeri Dilar on 19.06.2023.
//

import Foundation

func aURLSession(
    response: (Data, URLResponse),
    delay: TimeInterval = 0
) -> URLSession {
    let urlProtocol = URLProtocol.once(with: delay, response)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [urlProtocol]
    return URLSession(configuration: configuration)
}

extension URLProtocol {

    static func once(with delay: TimeInterval = 0, _ response: (Data, URLResponse)) -> URLProtocol.Type {
        return resultBuilder(with: delay, { response })
    }

    static func resultBuilder(with delay: TimeInterval = 0, _ resultBuilder: @escaping () -> (Data, URLResponse)) -> URLProtocol.Type {
        URLProtocolStub.customResultBuilder = resultBuilder
        URLProtocolStub.delay = delay
        return URLProtocolStub.self
    }

    private class URLProtocolStub: URLProtocol {

        static var customResultBuilder: (() -> (Data, URLResponse))?
        static var delay: TimeInterval = 0

        private var instanceResultBuilder: (() -> (Data, URLResponse))? {
            return URLProtocolStub.customResultBuilder
        }

        private var instanceDelay: TimeInterval {
            return URLProtocolStub.delay
        }

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let resultBuilder = instanceResultBuilder else { return }

            let (data, response) = resultBuilder()

            DispatchQueue.main.asyncAfter(deadline: .now() + instanceDelay) {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }

        override func stopLoading() { }
    }
}

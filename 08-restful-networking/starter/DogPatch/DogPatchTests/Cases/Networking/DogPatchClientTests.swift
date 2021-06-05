/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import XCTest
@testable import DogPatch

class DogPatchClientTests: XCTestCase {

  var sut: DogPatchClient!

  var baseURL: URL!
  var mockSession: MockURLSession!

  override func setUp() {
    super.setUp()
    baseURL = URL(string: "https://example.com/api/v1/")!
    mockSession = MockURLSession()
    sut = DogPatchClient(baseURL: baseURL, session: mockSession, responseQueue: nil)
  }

  override func tearDown() {
    baseURL = nil
    mockSession = nil
    sut = nil
    super.tearDown()
  }

  func test_init_sets_baseURL() {
    // then
    XCTAssertEqual(sut.baseURL, baseURL)
  }

  func test_init_sets_session() {
    // then
    XCTAssertEqual(sut.session, mockSession)
  }

  func test_init_sets_responseQueue() {
    // given
    let responseQueue = DispatchQueue.main

    // when
    sut = DogPatchClient(baseURL: baseURL,
                         session: mockSession,
                         responseQueue: responseQueue)

    // then
    XCTAssertEqual(sut.responseQueue, responseQueue)
  }

  func test_getDogs_callsExpectedURL() {
    // given
    let getDogsURL = URL(string: "dogs", relativeTo: baseURL)!

    // when
    let mockTask = sut.getDogs() { _, _ in } as! MockURLSessionDataTask

    // then
    XCTAssertEqual(mockTask.url, getDogsURL)
  }

  func test_getDogs_callsResumeOnTask() {
    // when
    let mockTask = sut.getDogs() { _, _ in } as! MockURLSessionDataTask

    // then
    XCTAssertTrue(mockTask.calledResume)
  }

  func test_getDogs_givenResponseStatusCode500_callsCompletion() {
    // given
    let getDogsURL = URL(string: "dogs", relativeTo: baseURL)!
    let response = HTTPURLResponse(url: getDogsURL,
                                   statusCode: 500,
                                   httpVersion: nil,
                                   headerFields: nil)

    // when
    var calledCompletion = false
    var receivedDogs: [Dog]? = nil
    var receivedError: Error? = nil

    let mockTask = sut.getDogs() { dogs, error in
      calledCompletion = true
      receivedDogs = dogs
      receivedError = error
    } as! MockURLSessionDataTask

    mockTask.completionHandler(nil, response, nil)

    // then
    XCTAssertTrue(calledCompletion)
    XCTAssertNil(receivedDogs)
    XCTAssertNil(receivedError)
  }

  func test_getDogs_givenError_callsCompletionWithError() throws {
    // given
    let response = HTTPURLResponse(url: baseURL,
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: nil)
    let expectedError = NSError(domain: "com.DogPatchTests",
                                code: 42)

    // when
    var calledCompletion = false
    var receivedDogs: [Dog]? = nil
    var receivedError: Error? = nil

    let mockTask = sut.getDogs() { dogs, error in
      calledCompletion = true
      receivedDogs = dogs
      receivedError = error as NSError?
      } as! MockURLSessionDataTask

    mockTask.completionHandler(nil, response, expectedError)

    // then
    XCTAssertTrue(calledCompletion)
    XCTAssertNil(receivedDogs)

    let actualError = try XCTUnwrap(receivedError as NSError?)
    XCTAssertEqual(actualError, expectedError)
  }

  func test_getDogs_givenValidJSON_callsCompletionWithDogs()
    throws {
      // given
      let data =
        try Data.fromJSON(fileName: "GET_Dogs_Response")

      let decoder = JSONDecoder()
      let dogs = try decoder.decode([Dog].self, from: data)

      // when
      let result = whenGetDogs(data: data)

      // then
      XCTAssertTrue(result.calledCompletion)
      XCTAssertEqual(result.dogs, dogs)
      XCTAssertNil(result.error)
  }

  func test_getDogs_givenInvalidJSON_callsCompletionWithError()
    throws {
    // given
    let data = try Data.fromJSON(
      fileName: "GET_Dogs_MissingValuesResponse")

    var expectedError: NSError!
    let decoder = JSONDecoder()
    do {
      _ = try decoder.decode([Dog].self, from: data)
    } catch {
      expectedError = error as NSError
    }

    // when
    let result = whenGetDogs(data: data)

    // then
    XCTAssertTrue(result.calledCompletion)
    XCTAssertNil(result.dogs)

    let actualError = try XCTUnwrap(result.error as NSError?)
    XCTAssertEqual(actualError.domain, expectedError.domain)
    XCTAssertEqual(actualError.code, expectedError.code)
  }

  func test_getDogs_givenHTTPStatusError_dispatchesToResponseQueue() {
    // given
    mockSession.givenDispatchQueue()
    sut = DogPatchClient(baseURL: baseURL,
                         session: mockSession,
                         responseQueue: .main)

    let expectation = self.expectation(
      description: "Completion wasn't called")

    // when
    var thread: Thread!
    let mockTask = sut.getDogs() { dogs, error in
      thread = Thread.current
      expectation.fulfill()
      } as! MockURLSessionDataTask

    let response = HTTPURLResponse(url: baseURL,
                                   statusCode: 500,
                                   httpVersion: nil,
                                   headerFields: nil)
    mockTask.completionHandler(nil, response, nil)

    // then
    waitForExpectations(timeout: 0.2) { _ in
      XCTAssertTrue(thread.isMainThread)
    }
  }
}

extension DogPatchClientTests {
  func whenGetDogs(
    data: Data? = nil,
    statusCode: Int = 200,
    error: Error? = nil) ->
    (calledCompletion: Bool, dogs: [Dog]?, error: Error?) {

      let response = HTTPURLResponse(url: baseURL,
                                     statusCode: statusCode,
                                     httpVersion: nil,
                                     headerFields: nil)

      var calledCompletion = false
      var receivedDogs: [Dog]? = nil
      var receivedError: Error? = nil

      let mockTask = sut.getDogs() { dogs, error in
        calledCompletion = true
        receivedDogs = dogs
        receivedError = error as NSError?
        } as! MockURLSessionDataTask

      mockTask.completionHandler(data, response, error)
      return (calledCompletion, receivedDogs, receivedError)
  }
}

class MockURLSession: URLSession {
  var queue: DispatchQueue? = nil

  func givenDispatchQueue() {
    queue = DispatchQueue(label: "com.DogPatchTests.MockSession")
  }

  override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    return MockURLSessionDataTask(completionHandler: completionHandler,
                                  url: url,
                                  queue: queue)
  }
}

class MockURLSessionDataTask: URLSessionDataTask {
  var completionHandler: (Data?, URLResponse?, Error?) -> Void
  var url: URL
  var calledResume = false

  init(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void, url: URL, queue: DispatchQueue?) {
    if let queue = queue {
      self.completionHandler = { data, response, error in
        queue.async() {
          completionHandler(data, response, error)
        }
      }
    } else {
      self.completionHandler = completionHandler
    }

    self.url = url

    super.init()
  }

  override func resume() {
    calledResume = true
  }
}

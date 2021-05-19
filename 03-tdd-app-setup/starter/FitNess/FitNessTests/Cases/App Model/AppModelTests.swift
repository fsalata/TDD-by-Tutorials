//
//  AppModelTests.swift
//  FitNessTests
//
//  Created by Fabio Cezar Salata on 19/05/21.
//  Copyright © 2021 Razeware. All rights reserved.
//

import XCTest
@testable import FitNess

class AppModelTests: XCTestCase {

  var sut: AppModel!

  override func setUp() {
    super.setUp()

    sut = AppModel()
  }

  override func tearDown() {
    sut = nil

    super.tearDown()
  }

  func testAppModel_whenInitialized_isInNotStartedState() {
    let initialState = sut.appState
    XCTAssertEqual(initialState, AppState.notStarted)
  }

  func testAppModel_wheStarted_isInProgressState() {
    // when started
    sut.start()

    // then it is in inProgress
    let observedState = sut.appState
    XCTAssertEqual(observedState, AppState.inProgress)
  }
}

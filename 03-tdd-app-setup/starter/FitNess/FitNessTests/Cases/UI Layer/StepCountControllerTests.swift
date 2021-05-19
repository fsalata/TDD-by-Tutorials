//
//  StepCountControllerTests.swift
//  FitNessTests
//
//  Created by Fabio Cezar Salata on 19/05/21.
//  Copyright © 2021 Razeware. All rights reserved.
//

import XCTest
@testable import FitNess

class StepCountControllerTests: XCTestCase {

  var sut: StepCountController!

  override func setUp() {
    super.setUp()

    sut = StepCountController()
  }

  override func tearDown() {
    sut = nil

    super.tearDown()
  }

  // MARK: Initial State
  func testController_whenCreated_buttonLabelIsStart() {
    // when
    sut.loadViewIfNeeded()

    // then
    let text = sut.startButton.title(for: .normal)
    XCTAssertEqual(text, AppState.notStarted.nextStateButtonLabel)
  }

  // MARK: In progress
  func testController_whenStartTapped_appIsInProgress() {
    // when
    callStartStopPause()

    // then
    let state = AppModel.instance.appState
    XCTAssertEqual(state, AppState.inProgress)
  }

  func testController_whenStartTapped_buttonLabelIsPause() {
    // when
    callStartStopPause()

    // then
    let text = sut.startButton.title(for: .normal)
    XCTAssertEqual(text, AppState.inProgress.nextStateButtonLabel)
  }
}

private extension StepCountControllerTests {
  func callStartStopPause() {
    sut.startStopPause(nil)
  }
}

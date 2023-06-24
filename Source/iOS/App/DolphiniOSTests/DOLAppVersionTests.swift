// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

import DolphiniOS
import XCTest

class DOLAppVersionTests: XCTestCase {
  func testNotEqualDifferentMajor() throws {
    XCTAssertNotEqual(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "99.22.33b44 (55)"))
  }
  
  func testNotEqualDifferentMinor() throws {
    XCTAssertNotEqual(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.99.33b44 (55)"))
  }
  
  func testNotEqualDifferentPatch() throws {
    XCTAssertNotEqual(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.99b44 (55)"))
  }
  
  func testNotEqualDifferentBeta() throws {
    XCTAssertNotEqual(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33b99 (55)"))
  }
  
  func testNotEqualDifferentBuild() throws {
    XCTAssertNotEqual(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33b44 (99)"))
  }
  
  func testNotEqualBetaAndNonBeta() throws {
    XCTAssertNotEqual(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33 (55)"))
  }
  
  func testEqualBeta() throws {
    XCTAssertEqual(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33b44 (55)"))
  }
  
  func testEqualNonBeta() throws {
    XCTAssertEqual(DOLAppVersion(jsonVersion: "11.22.33 (55)"), DOLAppVersion(jsonVersion: "11.22.33 (55)"))
  }
  
  func testLessThanLargerMajor() throws {
    XCTAssertLessThan(DOLAppVersion(jsonVersion: "11.22.33 (55)"), DOLAppVersion(jsonVersion: "99.22.33 (55)"))
  }
  
  func testLessThanLargerMinor() throws {
    XCTAssertLessThan(DOLAppVersion(jsonVersion: "11.22.33 (55)"), DOLAppVersion(jsonVersion: "11.99.33 (55)"))
  }
  
  func testLessThanLargerPatch() throws {
    XCTAssertLessThan(DOLAppVersion(jsonVersion: "11.22.33 (55)"), DOLAppVersion(jsonVersion: "11.22.99 (55)"))
  }
  
  func testLessThanLargerBeta() throws {
    XCTAssertLessThan(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33b99 (55)"))
  }
  
  func testLessThanLargerBuild() throws {
    XCTAssertLessThan(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33 (99)"))
  }
  
  func testLessThanBetaAndNonBeta() throws {
    XCTAssertLessThan(DOLAppVersion(jsonVersion: "11.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33 (55)"))
  }
  
  //
  
  func testGreaterThanLargerMajor() throws {
    XCTAssertGreaterThan(DOLAppVersion(jsonVersion: "99.22.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33b44 (55)"))
  }
  
  func testGreaterThanLargerMinor() throws {
    XCTAssertGreaterThan(DOLAppVersion(jsonVersion: "11.99.33b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33b44 (55)"))
  }
  
  func testGreaterThanLargerPatch() throws {
    XCTAssertGreaterThan(DOLAppVersion(jsonVersion: "11.22.99b44 (55)"), DOLAppVersion(jsonVersion: "11.22.33b44 (55)"))
  }
  
  func testGreaterThanLargerBeta() throws {
    XCTAssertGreaterThan(DOLAppVersion(jsonVersion: "11.22.33b99 (55)"), DOLAppVersion(jsonVersion: "11.22.33b44 (55)"))
  }
  
  func testGreaterThanLargerBuild() throws {
    XCTAssertGreaterThan(DOLAppVersion(jsonVersion: "11.22.33b44 (99)"), DOLAppVersion(jsonVersion: "11.22.33b44 (55)"))
  }
  
  func testGreaterThanBetaAndNonBeta() throws {
    XCTAssertGreaterThan(DOLAppVersion(jsonVersion: "11.22.33 (55)"), DOLAppVersion(jsonVersion: "11.22.33b44 (55)"))
  }
  
  func testNotLessThanSameVersion() throws {
    XCTAssertGreaterThan(DOLAppVersion(jsonVersion: "11.22.33 (55)"), DOLAppVersion(jsonVersion: "11.22.33 (55)"))
  }
}


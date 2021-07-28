import XCTest
@testable import SwiftOT

class OpArrayTests: XCTestCase {
  func testOpsCount() throws {
    var ops = [Op]()
    checkLen(ops: ops, bl: 0, tl: 0)
    ops.append(Op(n: 5))
    checkLen(ops: ops, bl: 5, tl: 5)
    ops.append(Op(s: "abc"))
    checkLen(ops: ops, bl: 5, tl: 8)
    ops.append(Op(n: 2))
    checkLen(ops: ops, bl: 7, tl: 10)
    ops.append(Op(n: -2))
    checkLen(ops: ops, bl: 9, tl: 10)
  }
  
  func checkLen(ops: [Op], bl: Int, tl: Int) {
    let (ret, del, ins) = ops.opCount()
    var l = ret + del
    if l != bl {
      XCTFail("Base len \(l) != \(bl)")
    }
    l = ret + ins
    if l != tl {
      XCTFail("Target len \(l) != \(tl)")
    }
  }
  
  func testOpsMerge() throws {
    var ops: [Op] = [Op(n: 5),
                       Op(n: 2),
                       Op(),
                       Op(s: "lo"),
                       Op(s: "rem"),
                       Op(),
                       Op(n: -3),
                       Op(n: -2),
                       Op()]
    let mergedOps = ops.opMerge()
    XCTAssertEqual(mergedOps.count, 3)
  }
  
  func testOpsEqual() throws {
    var a = [Op]()
    var b = [Op]()
    XCTAssertEqual(a, b)
    
    a = [Op(n: 7), Op(s: "lorem"), Op(n: -5)]
    XCTAssertNotEqual(a, b)
    
    b = [Op(n: 7), Op(s: "lorem"), Op(n: -5)]
    XCTAssertEqual(a, b)
  }
  
  func composeTestCases() -> [(a: [Op], b: [Op], ab: [Op])] {
    [
      (
        [Op](arrayLiteral: Op(n: 3), Op(n: -1)),
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 2)),
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 2), Op(n: -1))
      ),
      (
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 2)),
        [Op](arrayLiteral: Op(n: 4), Op(n: -2)),
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: -2))
      ),
      (
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag")),
        [Op](arrayLiteral: Op(n: 2), Op(n: -1), Op(n: 1)),
        [Op](arrayLiteral: Op(n: 1), Op(s: "tg"))
      )
    ]
  }
  
  func testOpsCompose() throws {
    for testCase in composeTestCases() {
      let ab = try testCase.a.compose(with: testCase.b)
      XCTAssertEqual(ab, testCase.ab)
    }
  }
  
  func transformTestCases() -> [(a: [Op], b: [Op], a1: [Op], b2: [Op])] {
    [
      (
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 2)),
        [Op](arrayLiteral: Op(n: 2), Op(n: -1)),
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 1)),
        [Op](arrayLiteral: Op(n: 5), Op(n: -1))
      ),
      (
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 2)),
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 2)),
        [Op](arrayLiteral: Op(n: 1), Op(s: "tag"), Op(n: 5)),
        [Op](arrayLiteral: Op(n: 4), Op(s: "tag"), Op(n: 2))
      ),
      (
        [Op](arrayLiteral: Op(n: 1), Op(n: -2)),
        [Op](arrayLiteral: Op(n: 2), Op(n: -1)),
        [Op](arrayLiteral: Op(n: 1), Op(n: -1)),
        [Op](arrayLiteral: Op(n: 1))
      ),
      (
        [Op](arrayLiteral: Op(n: 2), Op(n: -1)),
        [Op](arrayLiteral: Op(n: 1), Op(n: -2)),
        [Op](arrayLiteral: Op(n: 1)),
        [Op](arrayLiteral: Op(n: 1), Op(n: -1))
      )
    ]
  }
  
  func testOpsTransform() throws {
    for testCase in transformTestCases() {
      let (a1, b1) = try testCase.a.transform(with: testCase.b)
      XCTAssertEqual(a1, testCase.a1)
      XCTAssertEqual(b1, testCase.b2)
    }
  }
  
  func testInitWithInsertFirst() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 0, length: 0),
                          replacementText: "1234")
    XCTAssertEqual(ops.count, 2)
    XCTAssertEqual(ops[0], Op(s: "1234"))
    XCTAssertEqual(ops[1], Op(n: 32))
  }
  
  func testInitWithInsertMiddle() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 7, length: 0),
                          replacementText: "1234")
    XCTAssertEqual(ops.count, 3)
    XCTAssertEqual(ops[0], Op(n: 7))
    XCTAssertEqual(ops[1], Op(s: "1234"))
    XCTAssertEqual(ops[2], Op(n: 25))
  }
  
  func testInitWithInsertLast() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 32, length: 0),
                          replacementText: "1234")
    XCTAssertEqual(ops.count, 3)
    XCTAssertEqual(ops[0], Op(n: 32))
    XCTAssertEqual(ops[1], Op(s: "1234"))
    XCTAssertTrue(ops[2].isNoop)
  }
  
  func testInitWithDeleteMiddle() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 7, length: 2),
                          replacementText: "")
    XCTAssertEqual(ops.count, 3)
    XCTAssertEqual(ops[0], Op(n: 7))
    XCTAssertEqual(ops[1], Op(n: -2))
    XCTAssertEqual(ops[2], Op(n: 23))
  }
  
  func testInitWithDeleteLast() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 29, length: 3),
                          replacementText: "")
    XCTAssertEqual(ops.count, 3)
    XCTAssertEqual(ops[0], Op(n: 29))
    XCTAssertEqual(ops[1], Op(n: -3))
    XCTAssertTrue(ops[2].isNoop)
  }
  
  func testInitiWithDeleteFirst() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 0, length: 5),
                          replacementText: "")
    XCTAssertEqual(ops.count, 2)
    XCTAssertEqual(ops[0], Op(n: -5))
    XCTAssertEqual(ops[1], Op(n: 27))
  }
  
  func testInitWithReplaceRangeFirst() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 0, length: 3),
                          replacementText: "123")
    XCTAssertEqual(ops.count, 3)
    XCTAssertEqual(ops[0], Op(n: -3))
    XCTAssertEqual(ops[1], Op(s: "123"))
    XCTAssertEqual(ops[2], Op(n: 29))
  }
  
  func testInitWithReplaceRangeMiddle() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 7, length: 4),
                          replacementText: "1234")
    XCTAssertEqual(ops.count, 4)
    XCTAssertEqual(ops[0], Op(n: 7))
    XCTAssertEqual(ops[1], Op(n: -4))
    XCTAssertEqual(ops[2], Op(s: "1234"))
    XCTAssertEqual(ops[3], Op(n: 21))
  }
  
  func testInitWithReplaceRangeLast() throws {
    let current = "abcd efgh ijkl mnop qrst uvwx yz"
    let ops = [Op].init(currentText: current,
                          changeRange: NSRange(location: 29, length: 3),
                          replacementText: "123")
    XCTAssertEqual(ops.count, 4)
    XCTAssertEqual(ops[0], Op(n: 29))
    XCTAssertEqual(ops[1], Op(n: -3))
    XCTAssertEqual(ops[2], Op(s: "123"))
    XCTAssertTrue(ops[3].isNoop)
  }
}


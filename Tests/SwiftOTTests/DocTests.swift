import XCTest
@testable import SwiftOT

class DocTests: XCTestCase {
  struct OpTest {
    var text: String
    var want: String
    var ops: [Op]
  }
  
  func testDocPos() throws {
    let doc = Doc(s: "abc")
    let off = doc.pos(index: 3, last: Pos())
    XCTAssertTrue(off.isValid)
  }
  
  func testDocApply() throws {
    let tests = [OpTest]([
      OpTest(text: "abc",
             want: "atag",
             ops: [Op(n: 1),
                   Op(s: "tag"),
                   Op(n: -2)]),
      OpTest(text: "abc\ndef",
             want: "\nabc\ndef",
             ops: [Op(s: "\n"),
                   Op(n: 7)]),
      OpTest(text: "abc\ndef\nghi",
             want: "abcghi",
             ops: [Op(n: 3),
                   Op(n: -5),
                   Op(n: 3)]),
      OpTest(text: "abc\ndef\nghi",
             want: "ahoi",
             ops: [Op(n: 1),
                   Op(n: -3),
                   Op(s: "h"),
                   Op(n: -4),
                   Op(s: "o"),
                   Op(n: -2),
                   Op(n: 1)]),
    ])
    
    for (_, test) in tests.enumerated() {
      let doc = Doc(s: test.text)
      try doc.apply(ops: test.ops)
      let got = doc.toString()
      XCTAssertEqual(got, test.want)
    }
  }
  
  func testTransformCursorMovesCursorAfterForward() throws {
    let doc = Doc(s: "123456789")
    doc.cursors = [Cursor(id: "1", position: 3), Cursor(id: "2", position: 7)]
    let ops = [Op(n: 4), Op(s: "a"), Op(n: 5)]
    try doc.apply(ops: ops)
    
    XCTAssertEqual(doc.cursors.count, 2)
    
    XCTAssertEqual(doc.cursors[0].id, "1")
    XCTAssertEqual(doc.cursors[0].position, 3)
    
    XCTAssertEqual(doc.cursors[1].id, "2")
    XCTAssertEqual(doc.cursors[1].position, 8)
  }
  
  func testTransformCursorMovesCursorBack() throws {
    let doc = Doc(s: "123456789")
    doc.cursors = [Cursor(id: "1", position: 3), Cursor(id: "2", position: 7)]
    let ops = [Op(n: 4), Op(n: -1), Op(n: 4)]
    try doc.apply(ops: ops)
    
    XCTAssertEqual(doc.cursors.count, 2)
    
    XCTAssertEqual(doc.cursors[0].id, "1")
    XCTAssertEqual(doc.cursors[0].position, 3)
    
    XCTAssertEqual(doc.cursors[1].id, "2")
    XCTAssertEqual(doc.cursors[1].position, 6)
  }
}

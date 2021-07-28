import XCTest
@testable import SwiftOT
    
class ClientTests: XCTestCase {
  let delegate = MockClientDelegate()
  
  var doc: Doc!
  var client: Client!
  
  override func setUp() {
    super.setUp()
    doc = Doc(s: "old!")
    client = Client(doc: doc, rev: 0, buf: [], wait: [], resourceId: "")
    client.delegate = delegate
  }
  
  override func tearDown() {
    doc = nil
    client = nil
    super.tearDown()
  }
  
  @discardableResult
  func applyA() throws -> [Op] {
    let a: [Op] = [Op(s: "g"), Op(n: 4)]
    try client.apply(ops: a)
    return a
  }
  
  @discardableResult
  func applyB() throws -> [Op] {
    let b: [Op] = [Op(n: 2), Op(n: -2), Op(n: 1)]
    try client.apply(ops: b)
    return b
  }
  
  @discardableResult
  func applyC() throws -> [Op] {
    let c = [Op(n: 2), Op(s: " cool"), Op(n: 1)]
    try client.apply(ops: c)
    return c
  }
  
  @discardableResult
  func recvD() throws -> [Op] {
    let recvOps = [Op(n: 1), Op(s: " is"), Op(n: 3)]
    try client.recv(ops: recvOps)
    return recvOps
  }
  
  func testApplyAString() throws {
    try applyA()
    let s = doc.toString()
    XCTAssertEqual(s, "gold!")
  }
  
  func testApplyAWaitingForAck() throws {
    let a = try applyA()
    XCTAssertEqual(a, client.wait, "Expected waiting for ack")
    XCTAssertEqual(a, delegate.sent[0], "Expected waiting for ack")
  }
  
  func testApplyABString() throws {
    try applyA()
    try applyB()
    let s = doc.toString()
    XCTAssertEqual(s, "go!")
  }
  
  func testApplyABBuffering() throws {
    try applyA()
    let b = try applyB()
    XCTAssertEqual(b, client.buf, "Expected buffering")
    XCTAssertEqual(delegate.sent.count, 1, "Expected buffering")
  }
  
  func testApplyABCString() throws {
    try applyA()
    try applyB()
    try applyC()
    
    let s = doc.toString()
    XCTAssertEqual(s, "go cool!")
  }
  
  func testApplyABCChangeBuffer() throws {
    try applyA()
    try applyB()
    try applyC()
    
    let cb = [Op(n: 2), Op(n: -2), Op(s: " cool"), Op(n: 1)]
    XCTAssertEqual(cb, client.buf, "Expected combining buffer")
    XCTAssertEqual(delegate.sent.count, 1, "Expected combining buffer")
  }
  
  func testApplyABCRecvString() throws {
    try applyA()
    try applyB()
    try applyC()
    try recvD()

    let s = doc.toString()
    XCTAssertEqual(s, "go is cool!")
  }
  
  func testApplyABCRecvTransformWait() throws {
    try applyA()
    try applyB()
    try applyC()
    try recvD()
    
    XCTAssertEqual([Op(s: "g"), Op(n: 7)],
                   client.wait,
                   "Expected transform wait")
  }
  
  func testApplyABCRecvTransformBuf() throws {
    try applyA()
    try applyB()
    try applyC()
    try recvD()
    
    let cb = [Op(n: 5), Op(n: -2), Op(s: " cool"), Op(n: 1)]
    XCTAssertEqual(cb,
                   client.buf,
                   "Expected tranform buf")
  }
  
  func testApplyABCRecvAckFlushesBuffer() throws {
    try applyA()
    try applyB()
    try applyC()
    try recvD()
    try client.ack()
    
    let cb = [Op(n: 5), Op(n: -2), Op(s: " cool"), Op(n: 1)]
    XCTAssertEqual(client.buf.count, 0, "Expected flushed")
    XCTAssertEqual(client.wait, cb, "Expected flushed")
    XCTAssertEqual(delegate.sent.count, 2, "Expected flushed")
    XCTAssertEqual(delegate.sent[1], cb, "Expected flushed")
  }
  
  func testApplyABCRecvAckAckFlushesAll() throws {
    try applyA()
    try applyB()
    try applyC()
    try recvD()
    try client.ack()
    try client.ack()
    XCTAssertEqual(client.buf.count, 0, "Expected flushed")
    XCTAssertEqual(client.wait.count, 0, "Expected flushed")
    XCTAssertEqual(delegate.sent.count, 2, "Expected flushed")
  }
}

class MockClientDelegate: ClientDelegate {
  var sent = [[Op]]()
  
  func send(rev: Int, ops: [Op], sender: Client) {
    sent.append(ops)
  }
}


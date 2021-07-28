//
//  Op.swift
//  
//
//  Created by Zachary Rhodes on 7/27/21.
//

import Foundation

public let cursorScalar = "\u{E000}"

public protocol OpProviding {
  var n: Int { get set }
  var s: String { get set }
}

extension OpProviding {
  var isNoop: Bool {
    return n == 0 && s.isEmpty
  }
}

public struct Op: Codable, Equatable {
  var n: Int
  var s: String
  
  public init(n: Int = 0, s: String = "") {
    self.n = n
    self.s = s
  }
  
  public init(retain: Int) {
    self.init(n: retain, s: "")
  }
  
  public init(delete: Int) {
    var delete = delete
    delete.negate()
    self.init(n: delete, s: "")
  }
  
  public init(insert: String) {
    self.init(n: 0, s: insert)
  }
  
  public var isNoop: Bool {
    return n == 0 && s.isEmpty
  }
}

public class Cursor {
  var id: String
  var position: Int
  
  public lazy var op: Op = {
    return Op(n: 0, s: cursorScalar)
  }()
  
  public init(id: String, position: Int) {
    self.id = id
    self.position = position
  }
}

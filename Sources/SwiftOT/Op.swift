//
//  Op.swift
//  
//
//  Created by Zachary Rhodes on 7/27/21.
//

import Foundation

let cursorScalar = "\u{E000}"

protocol OpProviding {
  var n: Int { get set }
  var s: String { get set }
}

extension OpProviding {
  var isNoop: Bool {
    return n == 0 && s.isEmpty
  }
}

struct Op: Codable, Equatable {
  var n: Int
  var s: String
  
  init(n: Int = 0, s: String = "") {
    self.n = n
    self.s = s
  }
  
  init(retain: Int) {
    self.init(n: retain, s: "")
  }
  
  init(delete: Int) {
    var delete = delete
    delete.negate()
    self.init(n: delete, s: "")
  }
  
  init(insert: String) {
    self.init(n: 0, s: insert)
  }
  
  var isNoop: Bool {
    return n == 0 && s.isEmpty
  }
}

class Cursor {
  var id: String
  var position: Int
  
  lazy var op: Op = {
    return Op(n: 0, s: cursorScalar)
  }()
  
  init(id: String, position: Int) {
    self.id = id
    self.position = position
  }
}

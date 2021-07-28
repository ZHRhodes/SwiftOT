//
//  File.swift
//  
//
//  Created by Zachary Rhodes on 7/27/21.
//

import Foundation

class Doc {
  var lines = [[UnicodeScalar]]()
  var size: Int = 0
  
  var cursors: [Cursor] = []
  
  init(s: String) {
    var b = s.startIndex
    let newlineScalar = UnicodeScalar(10)!
    for (i, r) in s.enumerated() {
      size += 1
      if r.unicodeScalars.first == newlineScalar {
        let idx = s.index(s.startIndex, offsetBy: i)
        let substr = s[b..<idx].flatMap{ $0.unicodeScalars.map{$0} }
        lines.append(substr)
        b = s.index(idx, offsetBy: 1)
      }
    }
    let substr = s[b...].flatMap{ $0.unicodeScalars.map{$0} }
    lines.append(substr)
  }
  
  func toString() -> String {
    let joinedScalars = Array(lines.joined(separator: [UnicodeScalar(10)]))
    return String(joinedScalars.map{Character($0)})
  }
  
  func pos(index: Int, last: Pos) -> Pos {
    var n = index - last.index + last.offset
    for (i, l) in lines[last.line...].enumerated() {
      if l.count >= n {
        return Pos(index: index, line: i + last.line, offset: n)
      }
      n -= l.count + 1
    }
    return Pos(index: index, line: -1, offset: -1)
  }
  
  func apply(ops: [Op]) throws {
    var d = lines
    var p = Pos()
    var pops = [PosOp]()

    cursors = try transformCursors(cursors, with: ops)
    
    for (_, op) in ops.enumerated() {
      if op.n > 0 {
        p = pos(index: p.index + op.n, last: p)
        if !p.isValid {
          throw OTError.invalidDocumentIndex(p.index)
        }
      } else if op.n < 0 {
        pops.append(PosOp(pos: p, op: op))
        p = pos(index: p.index - op.n, last: p)
        if !p.isValid {
          throw OTError.invalidDocumentIndex(p.index)
        }
      } else if !op.s.isEmpty {
        pops.append(PosOp(pos: p, op: op))
      }
    }
    
    guard (p.line == d.count-1) && (p.offset == d[p.line].count) else {
      throw OTError.operationDidntOperateOnWholeDoc
    }
    
    for i in (0..<pops.count).reversed() {
      let pop = pops[i]
      if pop.op.n < 0 {
        size += pop.op.n
        let end = pos(index: pop.pos.index - pop.op.n, last: pop.pos)
        if !end.isValid {
          throw OTError.invalidDocumentIndex(end.index)
        }
        let line = d[pop.pos.line]
        if pop.pos.line == end.line {
          let rest = line[end.offset...]
          d[pop.pos.line] = Array(line[..<pop.pos.offset] + rest)
          continue
        }
        let rest = d[end.line][end.offset...]
        d[pop.pos.line] = Array(line[..<pop.pos.offset] + rest)
        d = Array<Array<UnicodeScalar>>(d[..<(pop.pos.line+1)] + d[(end.line+1)...])
      } else if !pop.op.s.isEmpty {
        let insd = Doc(s: pop.op.s)
        size += insd.size
        var insl = insd.lines
        let line = d[pop.pos.line]
        let last = insl.count - 1
        insl[last].append(contentsOf: line[pop.pos.offset...])
        insl[0] = line[..<pop.pos.offset] + insl[0]
        if insl.count == 1 {
          d[pop.pos.line] = insl[0]
          continue
        }
        let need = d.count + insl.count - 1
        while d.count < need {
          d.append([])
        }
        let needIdx = d.index(d.startIndex, offsetBy: need)
        d[(pop.pos.line + insl.count)..<needIdx] = d[(pop.pos.line + 1)...]
        d = Array(d[..<needIdx])
        d[pop.pos.line..<(pop.pos.line + insl.count)] = ArraySlice(insl)
      }
    }
    
    lines = d
  }
  
  func transformCursors(_ cursors: [Cursor], with ops: [Op]) throws -> [Cursor] {
    var newCursors = [Cursor]()
    
    for cursor in cursors {
      guard cursor.position <= size else { continue }
      let retainToCursor = Op(n: cursor.position, s: "")
      let cursorOp = cursor.op
      let retainAfterCursor = Op(n: size - cursor.position, s: "")
      
      var newCursorOps = [Op]()
      do {
        (newCursorOps, _) = try [retainToCursor, cursorOp, retainAfterCursor].transform(with: ops)
      } catch {
        throw OTError.failedToTransformCursor(error)
      }
      
      var newPosition = 0
      for op in newCursorOps {
        if op.s == cursorScalar {
          break
        } else {
          if op.n == 0 {
            newPosition += op.s.count
          } else {
            newPosition += op.n
          }
        }
      }
      
      newCursors.append(Cursor(id: cursor.id, position: newPosition))
    }
    
    return newCursors
  }
  
  func setCursor(id: String, position: Int) {
    for (i, cursor) in cursors.enumerated() {
      if cursor.id == id {
        cursors[i].position = position
        return
      }
    }
    cursors.append(Cursor(id: id, position: position))
  }
  
  func removeCursor(id: String) {
    cursors.removeAll(where: { $0.id == id })
  }
}

struct PosOp {
  var pos: Pos
  var op: Op
}

struct Pos {
  var index: Int = 0
  var line: Int = 0
  var offset: Int = 0
  
  var isValid: Bool {
    return line >= 0 && offset >= 0
  }
}

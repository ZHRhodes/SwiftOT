//
//  OTError.swift
//  
//
//  Created by Zachary Rhodes on 7/27/21.
//

import Foundation

public enum OTError: Error {
  case composeRequiresConsecutiveOps
  case composeEncounteredAShortOpSequence
  case transformRequiresConcurrentOps
  case transformEncounteredAShortOpSequence
  case noPendingOperations
  case invalidDocumentIndex(Int)
  case operationDidntOperateOnWholeDoc
  case failedToTransformCursor(Error)
}

//
//  BaseSourceEditorCommand.swift
//  Localized String Shortcut
//
//  Created by Mateus Gustavo de Freitas e Silva on 26/11/16.
//  Copyright © 2016 Mateus Gustavo de Freitas e Silva. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XcodeKit
import Foundation

class BaseSourceEditorCommand: NSObject {
  struct LineAdjust {
    var line = -1
    var columns = 0
  }

  /// The NSLocalizedString format options
  ///
  /// - SwiftMinimumLocalizedString: NSLocalizedString(value, comment: "")
  /// - SwiftSimpleLocalizedString: NSLocalizedString(value, comment: comment)
  /// - SwiftCompleteLocalizedString: NSLocalizedString(key, value: value, comment: comment)
  /// - SwiftBundleLocalizedString: NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: comment)
  /// - ObjectiveCMinimumLocalizedString: NSLocalizedString(key, nil)
  /// - ObjectiveCSimpleLocalizedString: NSLocalizedString(key, comment)
  /// - ObjectiveCTableLocalizedString: NSLocalizedStringFromTable(key, tableName, comment)
  /// - ObjectiveCBundleLocalizedString: NSLocalizedStringFromTableInBundle(\(originalString), tableName, bundle, comment)
  /// - ObjectiveCWithDefaultLocalizedString: NSLocalizedStringWithDefaultValue(\(originalString), tableName, bundle, value, comment)
  enum CommandFormat {
    case SwiftMinimumLocalizedString
    case SwiftSimpleLocalizedString
    case SwiftCompleteLocalizedString
    case SwiftBundleLocalizedString
    case ObjectiveCMinimumLocalizedString
    case ObjectiveCSimpleLocalizedString
    case ObjectiveCTableLocalizedString
    case ObjectiveCBundleLocalizedString
    case ObjectiveCWithDefaultLocalizedString
  }

  let SWIFT_SOURCE = "public.swift-source"
  let OBJECTIVEC_SOURCE = "public.objective-c-source"
  let HEADER_FILE = "public.c-header"

  var updatedSelections = [XCSourceTextRange]()
  var lineAdjust = LineAdjust()

  /// Replace the selected strings in source file with NSLocalizedString function
  ///
  /// - Parameters:
  ///   - buffer: The string buffer
  ///   - format: The NSLocalizedString format
  func localizedString(in buffer: XCSourceTextBuffer, with format: CommandFormat) {
    for selected in buffer.selections {
      if let selectedRange = selected as? XCSourceTextRange {
        // If nothing is selected, exit
        if selectedRange.start.column == selectedRange.end.column && selectedRange.start.line == selectedRange.end.line {
          return
        }

        // Adjusts the selection to add the previous changes
        if selectedRange.start.line == lineAdjust.line {
          selectedRange.start.column = selectedRange.start.column + lineAdjust.columns
          selectedRange.end.column = selectedRange.end.column + lineAdjust.columns
        }

        // Gets the original string
        var originalString = text(inRange: selectedRange, inBuffer: buffer)

        // Makes the new string
        var newString = ""
        var newStringLength = 0
        var originalStringLength = 0

        // If is the end of line adds line break in new text
        if originalString.last == "\n" {
          newString = "\n"
          newStringLength = -1
        }

        originalString = String(originalString.dropLast())

        originalStringLength = originalStringLength + originalString.count

        // Updates the new string
        switch format {
          case .SwiftMinimumLocalizedString: newString = "NSLocalizedString(\(originalString), comment: \"\")" + newString
          case .SwiftSimpleLocalizedString: newString = "NSLocalizedString(\(originalString), comment: <#comment#>)" + newString
          case .SwiftCompleteLocalizedString: newString = "NSLocalizedString(<#key#>, value: \(originalString), comment: <#comment#>)" + newString
          case .SwiftBundleLocalizedString: newString = "NSLocalizedString(<#key#>, tableName: <#tableName#>, bundle: <#bundle#>, value: \(originalString), comment: <#comment#>)" + newString
          case .ObjectiveCMinimumLocalizedString: newString = "NSLocalizedString(\(originalString), nil)" + newString
          case .ObjectiveCSimpleLocalizedString: newString = "NSLocalizedString(\(originalString), <#comment#>)" + newString
          case .ObjectiveCTableLocalizedString: newString = "NSLocalizedStringFromTable(\(originalString), <#tableName#>, <#comment#>)" + newString
          case .ObjectiveCBundleLocalizedString: newString = "NSLocalizedStringFromTableInBundle(\(originalString), <#tableName#>, <#bundle#>, <#comment#>)" + newString
          case .ObjectiveCWithDefaultLocalizedString: newString = "NSLocalizedStringWithDefaultValue(<#key#>, <#tableName#>, <#bundle#>, \(originalString), <#comment#>)" + newString
        }

        newStringLength = newStringLength + newString.count

        // Replaces the old text with the new text
        replace(position: selectedRange.start, length: originalStringLength, with: newString, inBuffer: buffer)

        // Stores the position of the new text
        let selection = XCSourceTextRange()
        selection.start = selectedRange.start
        selection.end = XCSourceTextPosition(line: selectedRange.end.line, column: selectedRange.start.column + newStringLength)
        updatedSelections.append(selection)

        // Updates the line adjust
        if selectedRange.start.line != lineAdjust.line {
          lineAdjust.line = selectedRange.start.line
          lineAdjust.columns = 0
        }

        lineAdjust.columns = lineAdjust.columns + newString.count - originalStringLength
      }
    }
    
    buffer.selections.setArray(updatedSelections)
  }

  /// Returns a text in given position on buffer
  ///
  /// - Parameters:
  ///   - textRange: The position of the text to be returned
  ///   - buffer: The string buffer
  /// - Returns: The found text
  func text(inRange textRange: XCSourceTextRange, inBuffer buffer: XCSourceTextBuffer) -> String {
    if textRange.start.line == textRange.end.line {
      let lineText = buffer.lines[textRange.start.line] as! String
      let from = lineText.index(lineText.startIndex, offsetBy: textRange.start.column)
      let to = lineText.index(lineText.startIndex, offsetBy: textRange.end.column)

      return String(lineText[from...to])
    }

    var text = ""

    for aLine in textRange.start.line...textRange.end.line {
      let lineText = buffer.lines[aLine] as! String

      switch aLine {
      case textRange.start.line: text += lineText[lineText.index(lineText.startIndex, offsetBy: textRange.start.column)...]
      case textRange.end.line: text += lineText[..<lineText.index(lineText.startIndex, offsetBy: textRange.end.column + 1)]
      default: text += lineText
      }
    }

    return text
  }

  /// Replaces a text in the buffer
  ///
  /// - Parameters:
  ///   - position: The position of the text to be replaced
  ///   - length: The length of the text to be replaced
  ///   - newElements: The new text
  ///   - buffer: The string buffer
  func replace(position: XCSourceTextPosition, length: Int, with newElements: String, inBuffer buffer: XCSourceTextBuffer) {
    var lineText = buffer.lines[position.line] as! String

    var start = lineText.index(lineText.startIndex, offsetBy: position.column)
    var end = lineText.index(start, offsetBy: length)

    if length < 0 {
      swap(&start, &end)
    }

    lineText.replaceSubrange(start..<end, with: newElements)
    lineText.remove(at: lineText.index(before: lineText.endIndex)) //remove end "\n"

    buffer.lines[position.line] = lineText
  }
}

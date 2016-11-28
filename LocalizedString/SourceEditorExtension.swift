//
//  SourceEditorExtension.swift
//  Action
//
//  Created by Mateus Gustavo de Freitas e Silva on 25/11/16.
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

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
  func extensionDidFinishLaunching() {
    // If your extension needs to do any work at launch, implement this optional method.
  }

  var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
    let productIdentifier = Bundle.main.infoDictionary![kCFBundleIdentifierKey as String] as! String

    func definitionForClassNamed(_ className: String, commandName: String) -> [XCSourceEditorCommandDefinitionKey: Any] {
      return [XCSourceEditorCommandDefinitionKey.identifierKey: productIdentifier + className,
              XCSourceEditorCommandDefinitionKey.classNameKey: className,
              XCSourceEditorCommandDefinitionKey.nameKey: commandName]
    }

    let myDefinitions : [[XCSourceEditorCommandDefinitionKey: Any]] = [
      definitionForClassNamed(MinimumLocalizedStringCommand.className(), commandName: "Get a NSLocalizedString without comment"),
      definitionForClassNamed(SimpleLocalizedStringCommand.className(), commandName: "Get a NSLocalizedString with comment"),
      definitionForClassNamed(CompleteLocalizedStringCommand.className(), commandName: "Get a NSLocalizedString with key (Swift)"),
      definitionForClassNamed(BundleLocalizedStringCommand.className(), commandName: "Get NSLocalizedString with bundle"),
      definitionForClassNamed(TableLocalizedStringCommand.className(), commandName: "Get NSLocalizedString with table (Objective-C)"),
      definitionForClassNamed(WithDefaultValueLocalizedStringCommand.className(), commandName: "Get a NSLocalizedString with default value (Objective-C"),
      ]

    return myDefinitions
  }
}

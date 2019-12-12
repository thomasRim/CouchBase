//
//  String+fileName.swift
//  CB_DB
//
//  Created by V.Yevdokymov on 2019-12-12.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

extension String {
    func sanitizedFilename() -> String {
        var filename = self.replacingOccurrences(of: "[ ]+", with: "-",
                                                 options: String.CompareOptions.regularExpression,
                                                 range: Range(NSMakeRange(0, self.count), in: self))
        filename = filename.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let illegal = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        filename = filename.components(separatedBy: illegal).joined(separator: "")
        return filename
    }
}

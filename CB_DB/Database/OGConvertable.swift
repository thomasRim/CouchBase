//
//  OGConvertable.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 24.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import CouchbaseLiteSwift

protocol  OGConvertable: Codable {
    var id: String {get set}
    var entity: String {get set}

    func toDocument() -> MutableDocument
    mutating func fromDictionaryObject(doc: DictionaryObject)
}

extension OGConvertable {

    func toDocument() -> MutableDocument {
        let doc = MutableDocument(id:id)
        let mirr = Mirror(reflecting: self)

        for child in mirr.children {
            if let key = child.label as? String {
                if let value = child.value as? String {
                    doc.setString(value, forKey: key)
                } else if let value = child.value as? Bool {
                    doc.setBoolean(value, forKey: key)
                } else if let value = child.value as? Int {
                    doc.setInt(value, forKey: key)
                } else if let value = child.value as? [Any] {
                    doc.setArray( MutableArrayObject(data: value), forKey: key)
                }
            }
        }
        return doc
    }

    mutating  func fromDictionaryObject(doc: DictionaryObject) {
        let dict = doc.toDictionary()
        let data = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        let decoded = try! JSONDecoder().decode(Self.self, from: data)
        self = decoded
    }
}

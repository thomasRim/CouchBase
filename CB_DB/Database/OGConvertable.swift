//
//  OGConvertable.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 24.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import CouchbaseLite

enum OGConvertableAction: Int {
    case saveUpdate = 0
    case delete
}

protocol  OGConvertable: AnyObject, Codable {
    var id: String {get set}
    var entity: String {get set}

    func applyAction(_ action:OGConvertableAction)
    func toDocument() -> CBLMutableDocument
    static func fromDictionaryObject(doc: CBLDictionary) -> OGConvertable
    func delete()
}

extension OGConvertable {

    func applyAction(_ action: OGConvertableAction) {
        switch action {
        case .saveUpdate:
            OGDatabaseManager.save(self)
        case .delete:
            OGDatabaseManager.delete(self)
        }
    }
    
    func toDocument() -> CBLMutableDocument {
        let doc = CBLMutableDocument(id:id)
        let mirr = Mirror(reflecting: self)

        for child in mirr.children {
            if let key = child.label as String? {
                doc.setValue(child.value, forKey: key)
            }
        }
        return doc
    }

    static func fromDictionaryObject(doc: CBLDictionary) -> OGConvertable {
        let dict = doc.toDictionary()
        let data = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        let decoded = try! JSONDecoder().decode(Self.self, from: data)
        return decoded
    }
    
    func delete() {
        OGDatabaseManager.delete(self)
    }
}

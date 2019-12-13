
//
//  DatabaseManager.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 25.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLite

@objc(OGDatabaseManager)
class OGDatabaseManager: NSObject {

    var database: CBLDatabase
    fileprivate static let shared = OGDatabaseManager()

    override init() {
        //        do {
        try! self.database = CBLDatabase(name: "OGIntake")
        //        } catch let error {
        //            print("Fail to init database: \(error.localizedDescription)")
        //        }
    }

    static func source() -> CBLQueryDataSource {
        return CBLQueryDataSource.database(OGDatabaseManager.shared.database)
    }
    //MARK: - API

    static func allPractitioners() -> [OGPractitioner] {
        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGPractitioner().entity)),
                    orderBy: [CBLQueryOrdering.property("name").ascending()])

        let result = executeQuery(query, forType: OGPractitioner.self)
        return result.0
    }

    static func allClinics(for practitioner:OGPractitioner?) -> [OGClinic] {
        guard let practitioner = practitioner else { return [] }

        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGClinic().entity))
                        .andExpression(CBLQueryExpression.property("practitionerId")
                            .equal(to: CBLQueryExpression.string(practitioner.id)))
                , orderBy: [CBLQueryOrdering.property("name").ascending()])

        let result = executeQuery(query, forType: OGClinic.self)
        return result.0
    }

    static func practitioner(for clinic:OGClinic?) -> OGPractitioner? {
        guard let clinic = clinic else { return nil }

        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGPractitioner().entity))
                        .andExpression(CBLQueryExpression.property("id")
                            .equal(to: CBLQueryExpression.string(clinic.practitionerId))))

        let result = executeQuery(query, forType: OGPractitioner.self)
        return result.0.first
    }

    static func allPatients(for clinic:OGClinic?) -> [OGPatient] {
        guard let clinic = clinic else { return [] }
        
        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGPatient().entity))
                        .andExpression(CBLQueryExpression.property("clinicId")
                            .equal(to: CBLQueryExpression.string(clinic.id))))

        let result = executeQuery(query, forType: OGPatient.self)
        return result.0
    }

    static func clinic(for patient:OGPatient?) -> OGClinic? {
        guard let patient = patient else { return nil }

        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGClinic().entity))
                        .andExpression(CBLQueryExpression.property("id")
                            .equal(to: CBLQueryExpression.string(patient.clinicId))))

        let result = executeQuery(query, forType: OGClinic.self)
        return result.0.first
    }

    static func allOrders(for patient:OGPatient?, onlySubmitted:Bool = true) -> [OGOrder] {
        guard let patient = patient else { return [] }

        var whereExpression:CBLQueryExpression = CBLQueryExpression.property("entity")
            .equal(to: CBLQueryExpression.string(OGOrder().entity))
            .andExpression(CBLQueryExpression.property("patientId")
                .equal(to: CBLQueryExpression.string(patient.id)))
        if (onlySubmitted) {
            whereExpression = whereExpression.andExpression(CBLQueryExpression.property("submittedAt").notNullOrMissing())
        }
        
        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: whereExpression)

        let result = executeQuery(query, forType: OGOrder.self)
        return result.0
    }

    static func patient(for order:OGOrder?) -> OGPatient? {
        guard let order = order else { return nil }

        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGPatient().entity))
                        .andExpression(CBLQueryExpression.property("id")
                            .equal(to: CBLQueryExpression.string(order.patientId))))

        let result = executeQuery(query, forType: OGPatient.self)
        return result.0.first
    }

    static func allAssets(for order:OGOrder?) -> [OGAsset] {
        guard let order = order else { return [] }

        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGAsset().entity))
                        .andExpression(CBLQueryExpression.property("orderId")
                            .equal(to: CBLQueryExpression.string(order.id))))

        let result = executeQuery(query, forType: OGAsset.self)
        return result.0
    }
    
    static func asset(for id:String?) -> OGAsset? {
        guard let id = id else { return nil }

        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                    where: CBLQueryExpression.property("entity")
                        .equal(to: CBLQueryExpression.string(OGAsset().entity))
                        .andExpression(CBLQueryExpression.property("id")
                            .equal(to: CBLQueryExpression.string(id))))

        let result = executeQuery(query, forType: OGAsset.self)
        return result.0.first
    }

    static func order(for asset:OGAsset?) -> OGOrder? {
        guard let asset = asset else { return nil }

        let query = CBLQueryBuilder
        .select([CBLQuerySelectResult.all()],
                from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                where: CBLQueryExpression.property("entity")
                    .equal(to: CBLQueryExpression.string(OGOrder().entity))
                    .andExpression(CBLQueryExpression.property("id")
                        .equal(to: CBLQueryExpression.string(asset.orderId))))

        let result = executeQuery(query, forType: OGOrder.self)
        return result.0.first
    }
    
    // MARK: - Additional
    
    static func anyClinic() -> Bool {
        let query = CBLQueryBuilder
        .select([CBLQuerySelectResult.all()],
                from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                where: CBLQueryExpression.property("entity")
                    .equal(to: CBLQueryExpression.string(OGClinic().entity)))

        let result = executeQuery(query, forType: OGClinic.self, onlyGreaterZero: true)
        return result.1
    }

    static func anyParient() -> Bool {
        let query = CBLQueryBuilder
        .select([CBLQuerySelectResult.all()],
                from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                where: CBLQueryExpression.property("entity")
                    .equal(to: CBLQueryExpression.string(OGPatient().entity)))

        let result = executeQuery(query, forType: OGPatient.self, onlyGreaterZero: true)
        return result.1
    }
    
    static func anyOrder(onlySubmitted:Bool = false) -> Bool {
        var whereExpression:CBLQueryExpression = CBLQueryExpression.property("entity")
            .equal(to: CBLQueryExpression.string(OGOrder().entity))
        if (onlySubmitted) {
            whereExpression = whereExpression.andExpression(CBLQueryExpression.property("submittedAt").notNullOrMissing())
        }

        let query = CBLQueryBuilder
        .select([CBLQuerySelectResult.all()],
                from: CBLQueryDataSource.database(OGDatabaseManager.shared.database),
                where: whereExpression )

        let result = executeQuery(query, forType:OGOrder.self, onlyGreaterZero: true)
        return result.1
    }
    
    // MARK: - Actions

    static func executeQuery<T:OGConvertable>(_ query: CBLQuery, forType T:T.Type, onlyGreaterZero:Bool = false) -> ([T], Bool) {
        do {
            let result = try query.execute()

            if onlyGreaterZero == true {
                return ([], result.allResults().count > 0)
            } else {
                var objects:[T] = []

                for res in result {
                    guard let dict = (res as! CBLQueryResult).forKey(OGDatabaseManager.shared.database.name) else { return ([], false) }

                    if let obj = T.fromDictionaryObject(doc: dict) as? T {
                        objects.append(obj)
                    }
                }
                return (objects, true)
            }

        } catch {
            return ([], false)
        }
    }

    @discardableResult
    static func save(_ doc: OGConvertable?) -> Bool {
        guard let doc = doc?.toDocument() else { return false }
        do {
            try OGDatabaseManager.shared.database.save(doc)
            return true
        } catch let error {
            print("Document save error: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    static func delete(_ doc: OGConvertable?) -> Bool {
        guard let id = doc?.id else { return false }

        do {
            try OGDatabaseManager.shared.database.purgeDocument(withID: id)
            return true
        } catch let error {
            print("Document delete error: \(error.localizedDescription)")
            return false
        }
    }
    
    static func close() {
        do {
            try OGDatabaseManager.shared.database.close()
        } catch let error {
            print("Document close error: \(error.localizedDescription)")
        }
    }
}

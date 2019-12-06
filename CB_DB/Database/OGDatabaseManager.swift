
//
//  DatabaseManager.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 25.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

@objc(OGDatabaseManager)
class OGDatabaseManager: NSObject {

    var database: Database
    fileprivate static let shared = OGDatabaseManager()

    override init() {
//        do {
            try! self.database = Database(name: "OGIntake")
//        } catch let error {
//            print("Fail to init database: \(error.localizedDescription)")
//        }
    }

    //MARK: - API

    static func allPractitioners() -> [OGPractitioner] {
        var objects = [OGPractitioner]()

        let query = QueryBuilder
            .select(SelectResult.all(),
                    SelectResult.expression(Meta.id))
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGPractitioner().entity)))
            .orderBy(Ordering.property("name"))

        do {
            let results = try query.execute()
            for result in results {
                print("result \(result.count)")
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { continue }

                var obj = OGPractitioner()
                obj.fromDictionaryObject(doc: dict)
                objects.append(obj)
            }
        } catch {
            fatalError("Error running the query")
        }

        return objects
    }

    static func allClinics(for practitioner:OGPractitioner?) -> [OGClinic] {
        var objects = [OGClinic]()
        guard let practitioner = practitioner else { return objects }

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGClinic().entity))
                .and(Expression.property("paractitionerId").equalTo(Expression.string(practitioner.id))))
            .orderBy(Ordering.property("name"))

        do {
            let results = try query.execute()
            for result in results {
                print("result \(result.count)")
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { continue }

                var obj = OGClinic()
                obj.fromDictionaryObject(doc: dict)
                objects.append(obj)
            }
        } catch {
            fatalError("Error running the query")
        }

        return objects
    }

    static func practitioner(for clinic:OGClinic?) -> OGPractitioner? {
        guard let clinic = clinic else { return nil }

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGPractitioner().entity))
                .and(Expression.property("practitionerId").equalTo(Expression.string(clinic.practitionerId))))
            .limit(Expression.int(1))

        do {
            let results = try query.execute()
            if let result = results.allResults().first {
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { return nil }

                var obj = OGPractitioner()
                obj.fromDictionaryObject(doc: dict)
                return obj
            }
        } catch  {
            fatalError("Error running the query")
        }

        return nil
    }

    static func allPatients(for clinic:OGClinic) -> [OGPatient] {
        var objects = [OGPatient]()

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGPatient().entity)))
            .orderBy(Ordering.property("name"))

        do {
            let results = try query.execute()
            for result in results {
                print("result \(result.count)")
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { continue }

                var obj = OGPatient()
                obj.fromDictionaryObject(doc: dict)
                objects.append(obj)
            }
        } catch {
            fatalError("Error running the query")
        }

        return objects
    }

    static func clinic(for patient:OGPatient?) -> OGClinic? {
        guard let patient = patient else { return nil }

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGClinic().entity))
                .and(Expression.property("clinicId").equalTo(Expression.string(patient.clinicId))))
            .limit(Expression.int(1))

        do {
            let results = try query.execute()
            if let result = results.allResults().first {
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { return nil }

                var obj = OGClinic()
                obj.fromDictionaryObject(doc: dict)
                return obj
            }
        } catch  {
            fatalError("Error running the query")
        }

        return nil
    }

    static func allOrders(for patient:OGPatient) -> [OGOrder] {
        var objects = [OGOrder]()

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGOrder().entity)))
            .orderBy(Ordering.property("name"))

        do {
            let results = try query.execute()
            for result in results {
                print("result \(result.count)")
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { continue }

                var obj = OGOrder()
                obj.fromDictionaryObject(doc: dict)
                objects.append(obj)
            }
        } catch {
            fatalError("Error running the query")
        }

        return objects
    }

    static func patient(for order:OGOrder?) -> OGPatient? {
        guard let order = order else { return nil }
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGPatient().entity))
                .and(Expression.property("patientId").equalTo(Expression.string(order.patientId))))
            .limit(Expression.int(1))

        do {
            let results = try query.execute()
            if let result = results.allResults().first {
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { return nil }

                var obj = OGPatient()
                obj.fromDictionaryObject(doc: dict)
                return obj
            }
        } catch  {
            fatalError("Error running the query")
        }

        return nil
    }

    static func allAssets(for order:OGOrder) -> [OGAsset] {
        var objects = [OGAsset]()

        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGAsset().entity))
                .and(Expression.property("orderId").equalTo(Expression.string(order.id))))
            .orderBy(Ordering.property("caption"))

        do {
            let results = try query.execute()
            for result in results {
                print("result \(result.count)")
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { continue }

                var obj = OGAsset()
                obj.fromDictionaryObject(doc: dict)
                objects.append(obj)
            }
        } catch {
            fatalError("Error running the query")
        }

        return objects
    }

    static func order(for asset:OGAsset?) -> OGOrder? {
        guard let asset = asset else { return nil }
        let query = QueryBuilder
            .select(SelectResult.all())
            .from(DataSource.database(OGDatabaseManager.shared.database))
            .where(Expression.property("entity").equalTo(Expression.string(OGOrder().entity))
                .and(Expression.property("orderId").equalTo(Expression.string(asset.orderId))))
            .limit(Expression.int(1))

        do {
            let results = try query.execute()
            if let result = results.allResults().first {
                guard let dict = result.dictionary(forKey: OGDatabaseManager.shared.database.name) else { return nil }

                var obj = OGOrder()
                obj.fromDictionaryObject(doc: dict)
                return obj
            }
        } catch  {
            fatalError("Error running the query")
        }

        return nil
    }

    // MARK: - Actions

    static func save(_ doc: MutableDocument) -> Bool {
        do {
            try OGDatabaseManager.shared.database.saveDocument(doc)
            return true
        } catch let error {
            print("Document save error: \(error.localizedDescription)")
            return false
        }
    }

    static func delete(_ doc: MutableDocument) -> Bool {
        do {
            try OGDatabaseManager.shared.database.deleteDocument(doc)
            return true
        } catch let error {
            print("Document delete error: \(error.localizedDescription)")
            return false
        }
    }
}

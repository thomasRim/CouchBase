//
//  OGPatient+Order.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 08.12.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLite

extension OGPatient {

    func activeOrder() -> OGOrder {
        let existing = orders().first(where: {$0.submittedAt == nil})

        if let order = existing {
            return order
        } else {
            let order = OGOrder()
            order.patientId = id
            OGDatabaseManager.save(order)
            return order
        }
    }

    func lastSubmittedOrder() -> OGOrder? {
        let query = CBLQueryBuilder
            .select([CBLQuerySelectResult.all()],
                    from: OGDatabaseManager.source(),
                    where: CBLQueryExpression.property("entity").equal(to:CBLQueryExpression.string(OGOrder().entity))
                        .andExpression(CBLQueryExpression.property("submittedAt").notNullOrMissing()),
                    orderBy: [CBLQueryOrdering.property("submittedAt").ascending()])

        let result = OGDatabaseManager.executeQuery(query, forType: OGOrder.self)

        if let order = result.0.first {
            return order
        } else {
            return createNewOrder()
        }
    }

    func createNewOrder() -> OGOrder {
        let order = OGOrder()
        order.createDefaultAssets()
        order.patientId = self.id

        OGDatabaseManager.save(order)
        return order
    }

    func duplicateActiveOrder(from order:OGOrder?) {
        let order = self.activeOrder()
        order.duplicateFrom(order: order)
        OGDatabaseManager.save(order)
    }

    func resetActiveOrder() {
        let order = self.activeOrder()
        order.reset()
        OGDatabaseManager.save(order)
    }
}

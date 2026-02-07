//
//  FocusAreaEntity.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import Foundation
import CoreData

@objc(FocusAreaEntity)
public class FocusAreaEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var address: String?

}

//
//  DatabaseClient.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import Foundation

// swift concurrency도입 이전 기준으로 만들어졌으니.
// 컴파일러가 너무 엄격하게 검사하지 말아달라는 선언
@preconcurrency import CoreData
import ComposableArchitecture

@DependencyClient
struct CoreDataClient: Sendable {
    var fetch: @Sendable () async throws -> [FocusArea]
    var save: @Sendable (String, Double, Double, String) async throws -> Void
    var delete: @Sendable (UUID) async throws -> Void
}

extension CoreDataClient: DependencyKey {
    static let liveValue: CoreDataClient = {
        // Container를 한 번만 생성하고 캡처
        let container = NSPersistentContainer(name: "DBModel")

        // 동기적으로 로드 대기
        let semaphore = DispatchSemaphore(value: 0)
        var loadError: Error?

        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let error = loadError {
            fatalError("CoreData load failed: \(error)")
        }

        return CoreDataClient(
            fetch: {
                let context = container.viewContext
                let request = NSFetchRequest<FocusAreaEntity>(entityName: "FocusAreaEntity")
                request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusAreaEntity.createdAt, ascending: false)]

                return try await context.perform {
                    let entities = try context.fetch(request)
                    return entities.compactMap { entity in
                        guard let id = entity.id,
                              let title = entity.title,
                              let address = entity.address,
                              let createdAt = entity.createdAt else {
                            return nil
                        }
                        return FocusArea(
                            id: id,
                            title: title,
                            latitude: entity.latitude,
                            longitude: entity.longitude,
                            address: address,
                            createdAt: createdAt
                        )
                    }
                }
            },
            save: { title, latitude, longitude, address in
                print("📝 저장 시작 - title: '\(title)', address: '\(address)'")
                let context = container.newBackgroundContext()
                let id = UUID()
                let createdAt = Date()

                try await context.perform {
                    let entity = FocusAreaEntity(context: context)
                    entity.id = id
                    entity.title = title
                    entity.latitude = latitude
                    entity.longitude = longitude
                    entity.address = address
                    entity.createdAt = createdAt

                    print("📝 Entity 생성 완료 - id: \(id), title: \(entity.title ?? "nil")")

                    try context.save()
                    print("✅ 저장 성공")
                }
            },
            delete: { id in
                let context = container.newBackgroundContext()

                try await context.perform {
                    let request = NSFetchRequest<FocusAreaEntity>(entityName: "FocusAreaEntity")
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

                    if let entity = try context.fetch(request).first {
                        context.delete(entity)
                        try context.save()
                    }
                }
            }
        )
    }()
}

extension DependencyValues {
    var coreDataClient: CoreDataClient {
        get { self[CoreDataClient.self] }
        set { self[CoreDataClient.self] = newValue }
    }
}

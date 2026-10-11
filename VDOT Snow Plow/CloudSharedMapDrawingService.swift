//
//  CloudSharedMapDrawingService.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/11/26.
//

import Foundation
import CloudKit

final class CloudSharedMapDrawingService {

    static let shared =
        CloudSharedMapDrawingService()

    private init() {}

    private let database =
        CKContainer.default()
            .publicCloudDatabase

    private let recordType =
        "SharedMapDrawing"

    func saveDrawing(
        _ drawing: SharedMapDrawing
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    drawing.id.uuidString
            )

        let record =
            CKRecord(
                recordType:
                    recordType,
                recordID:
                    recordID
            )

        record["stormID"] =
            drawing.stormID.uuidString

        record["mapNumber"] =
            drawing.mapNumber

        record["createdByUserID"] =
            drawing.createdByUserID.uuidString

        record["createdByName"] =
            drawing.createdByName

        record["createdByRole"] =
            drawing.createdByRole.rawValue

        record["createdAt"] =
            drawing.createdAt

        let coordinateData =
            try JSONEncoder()
                .encode(
                    drawing.coordinates
                )

        record["coordinates"] =
            coordinateData as CKRecordValue

        try await database.save(
            record
        )

        print(
            "☁️ Shared map drawing uploaded:",
            drawing.mapNumber,
            drawing.createdByName,
            drawing.createdByRole.rawValue
        )
    }

    func fetchDrawings(
        stormID: UUID,
        mapNumber: String
    ) async throws
    -> [SharedMapDrawing] {

        let predicate =
            NSPredicate(
                format:
                    "stormID == %@ AND mapNumber == %@",
                stormID.uuidString,
                mapNumber
            )

        let query =
            CKQuery(
                recordType:
                    recordType,
                predicate:
                    predicate
            )

        let result =
            try await database.records(
                matching:
                    query
            )

        var drawings:
            [SharedMapDrawing] = []

        for (_, recordResult)
        in result.matchResults {

            guard
                case .success(
                    let record
                ) = recordResult
            else {
                continue
            }

            guard
                let id =
                    UUID(
                        uuidString:
                            record.recordID
                                .recordName
                    ),

                let stormIDString =
                    record["stormID"]
                        as? String,

                let recordStormID =
                    UUID(
                        uuidString:
                            stormIDString
                    ),

                let mapNumber =
                    record["mapNumber"]
                        as? String,

                let createdByUserIDString =
                    record["createdByUserID"]
                        as? String,

                let createdByUserID =
                    UUID(
                        uuidString:
                            createdByUserIDString
                    ),

                let createdByName =
                    record["createdByName"]
                        as? String,

                let roleRaw =
                    record["createdByRole"]
                        as? String,

                let createdByRole =
                    AppUserRole(
                        rawValue:
                            roleRaw
                    ),

                let createdAt =
                    record["createdAt"]
                        as? Date,

                let coordinateData =
                    record["coordinates"]
                        as? Data

            else {
                continue
            }

            let coordinates =
                try JSONDecoder()
                    .decode(
                        [SavedCoordinate].self,
                        from:
                            coordinateData
                    )

            drawings.append(
                SharedMapDrawing(
                    id:
                        id,
                    stormID:
                        recordStormID,
                    mapNumber:
                        mapNumber,
                    createdByUserID:
                        createdByUserID,
                    createdByName:
                        createdByName,
                    createdByRole:
                        createdByRole,
                    coordinates:
                        coordinates,
                    createdAt:
                        createdAt
                )
            )
        }

        return drawings.sorted {
            $0.createdAt <
                $1.createdAt
        }
    }
    
    func deleteDrawing(
        _ drawing: SharedMapDrawing
    ) async throws {

        let recordID =
            CKRecord.ID(
                recordName:
                    drawing.id.uuidString
            )

        try await database
            .deleteRecord(
                withID:
                    recordID
            )

        print(
            "🗑️ Shared drawing deleted:",
            drawing.mapNumber,
            drawing.createdByName
        )
    }
}

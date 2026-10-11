//
//  SupervisorMapReviewView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import SwiftUI

struct SupervisorMapReviewView: View {

    @ObservedObject var reviewRequestStore:
        MapReviewRequestStore
    
    @StateObject private var inspectionStore =
        MapReviewInspectionStore()
    @StateObject private var mapAssignmentStore =
        DriverMapAssignmentStore()

    let supervisorUser: AppUser

    var body: some View {

        List {

            let pending =
                reviewRequestStore.requests
                    .filter { request in

                        guard request.status == "pending"
                        else {
                            return false
                        }

                        let assignment =
                            mapAssignmentStore
                                .assignments
                                .first {
                                    $0.id ==
                                        request.assignmentID
                                }

                        return assignment?
                            .completedAt == nil
                    }
                    .sorted {
                        $0.requestedAt <
                            $1.requestedAt
                    }

            if pending.isEmpty {

                ContentUnavailableView(
                    "No Pending Map Checks",
                    systemImage:
                        "checkmark.circle",
                    description:
                        Text(
                            "Driver review requests will appear here."
                        )
                )

            } else {

                ForEach(
                    pending
                ) { request in

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(
                            "Map \(request.mapNumber)"
                        )
                        .font(
                            .headline
                        )

                        Text(
                            "Requested \(request.requestedAt.formatted(date: .abbreviated, time: .shortened))"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        HStack {
                            if let latest =
                                inspectionStore
                                    .latestInspection(
                                        for:
                                            request.id
                                    ) {

                                Label(
                                    "Current: \(latest.progress.rawValue)",
                                    systemImage:
                                        latest.progress == .done
                                        ? "checkmark.circle.fill"
                                        : "gauge.with.dots.needle.50percent"
                                )
                                .foregroundStyle(
                                    latest.progress == .done
                                    ? .green
                                    : .orange
                                )
                            }

                            Button("1/4") {

                                Task {

                                    await inspectionStore
                                        .saveInspection(
                                            request:
                                                request,
                                            supervisorUserID:
                                                supervisorUser.id,
                                            progress:
                                                .quarter
                                        )
                                }
                            }
                            .disabled(
                                canSelect(
                                    .quarter,
                                    for:
                                        request
                                ) == false
                            )

                            Button("1/2") {

                                Task {

                                    await inspectionStore
                                        .saveInspection(
                                            request:
                                                request,
                                            supervisorUserID:
                                                supervisorUser.id,
                                            progress:
                                                .half
                                        )
                                }
                            }
                            .disabled(
                                canSelect(
                                    .half,
                                    for:
                                        request
                                ) == false
                            )

                            Button("3/4") {

                                Task {

                                    await inspectionStore
                                        .saveInspection(
                                            request:
                                                request,
                                            supervisorUserID:
                                                supervisorUser.id,
                                            progress:
                                                .threeQuarter
                                        )
                                }
                            }
                            .disabled(
                                canSelect(
                                    .threeQuarter,
                                    for:
                                        request
                                ) == false
                            )

                            Button("Done") {

                                Task {

                                    await inspectionStore
                                        .saveInspection(
                                            request:
                                                request,
                                            supervisorUserID:
                                                supervisorUser.id,
                                            progress:
                                                .done
                                        )
                                }
                            }
                        }
                        .disabled(
                            canSelect(
                                .done,
                                for:
                                    request
                            ) == false
                        )
                        .buttonStyle(
                            .bordered
                        )
                    }
                    .padding(
                        .vertical,
                        4
                    )
                }
            }
        }
        .navigationTitle(
            "Map Checks"
        )
        .task {

            await reviewRequestStore
                .syncFromCloud()

            await inspectionStore
                .syncFromCloud()
            
            await mapAssignmentStore
                .syncFromCloud()
            
            await NotificationManager
                .shared
                .subscribeForMapAssignmentUpdates()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for:
                    .mapAssignmentChangedNotificationReceived
            )
        ) { _ in

            Task {

                print(
                    "🔄 Refreshing assignments after finish"
                )

                for attempt in 1...4 {

                    let previousCompletedCount =
                        mapAssignmentStore
                            .assignments
                            .filter {
                                $0.completedAt != nil
                            }
                            .count

                    await mapAssignmentStore
                        .syncFromCloud()

                    let newCompletedCount =
                        mapAssignmentStore
                            .assignments
                            .filter {
                                $0.completedAt != nil
                            }
                            .count

                    if newCompletedCount >
                        previousCompletedCount {

                        print(
                            "✅ Finished assignment visible on attempt",
                            attempt
                        )

                        break
                    }

                    try? await Task.sleep(
                        for:
                            .seconds(2)
                    )
                }
            }
        }
    }
    
    private func progressRank(
        _ progress: MapReviewProgress
    ) -> Int {

        switch progress {

        case .quarter:
            return 1

        case .half:
            return 2

        case .threeQuarter:
            return 3

        case .done:
            return 4
        }
    }
    
    private func canSelect(
        _ progress: MapReviewProgress,
        for request: MapReviewRequest
    ) -> Bool {

        guard let latest =
            inspectionStore
                .latestInspection(
                    for:
                        request.id
                )
        else {
            return true
        }

        return progressRank(progress) >
            progressRank(latest.progress)
    }
}

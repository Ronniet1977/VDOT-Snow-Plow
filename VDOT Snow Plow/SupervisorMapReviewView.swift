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

    let supervisorUser: AppUser

    var body: some View {

        List {

            let pending =
                reviewRequestStore.requests
                    .filter {
                        $0.status == "pending"
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
        }
    }
}

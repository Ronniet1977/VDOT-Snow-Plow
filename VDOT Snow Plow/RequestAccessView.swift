//
//  RequestAccessView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import SwiftUI

struct RequestAccessView: View {

    @ObservedObject var requestStore:
        UserAccessRequestStore
    @ObservedObject var userStore:
        AppUserStore

    let appleUserID: String

    @State private var name = ""
    @State private var companyName = ""
    @State private var truckVINLast4 = ""
    @State private var phoneNumber = ""

    @State private var submitted = false
    @State private var denialMessage:
        String?

    var body: some View {

        Form {

            Section(
                "Request Access"
            ) {

                TextField(
                    "Your Name",
                    text: $name
                )

                TextField(
                    "Truck Company Name",
                    text: $companyName
                )
                
                TextField(
                    "Phone Number",
                    text: $phoneNumber
                )
                .keyboardType(
                    .phonePad
                )

                TextField(
                    "Last 4 of Truck VIN",
                    text: $truckVINLast4
                )
                .textInputAutocapitalization(
                    .characters
                )
            }

            Section {

                Button(
                    "Submit Request"
                ) {

                    submitRequest()
                }
                .disabled(
                    !formIsValid
                )
            }

            if submitted {

                Section {

                    Text(
                        "Your access request was sent for approval."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            
            if let denialMessage {

                Section {

                    Text(
                        denialMessage
                    )
                    .foregroundStyle(
                        .red
                    )
                }
            }
        }
        .navigationTitle(
            "Request Access"
        )
        .task {

            await requestStore
                .syncFromCloud()

            while !Task.isCancelled {

                await userStore
                    .syncFromCloud()

                // Check for denial first
                do {

                    await requestStore
                        .syncFromCloud()

                    let myRequests =
                        requestStore.requests
                            .filter {
                                $0.appleUserID ==
                                    appleUserID
                            }

                    let decisions =
                        try await
                            CloudAccessRequestDecisionService
                                .shared
                                .fetchDecisions(
                                    for: appleUserID
                                )

                    if let denied =
                        decisions.first(
                            where: { decision in

                                decision.decision ==
                                    "denied" &&

                                myRequests.contains {
                                    $0.id ==
                                        decision.requestID
                                }
                            }
                        ) {

                        if let deniedRequest =
                            myRequests.first(
                                where: {
                                    $0.id ==
                                        denied.requestID
                                }
                            ) {

                            requestStore.delete(
                                deniedRequest
                            )
                        }

                        denialMessage =
                            "Your access request was denied. You may submit a new request."

                        submitted = false

                        print(
                            "🚫 Access denial detected:",
                            denied.requestID
                        )

                        // DO NOT break here.
                        // Keep watching in case they submit again.
                    }

                } catch {

                    print(
                        "❌ Decision check failed:",
                        error
                    )
                }

                // Then check for approval
                if userStore.users.contains(
                    where: {
                        $0.appleUserID ==
                            appleUserID &&
                        $0.isActive
                    }
                ) {

                    print(
                        "✅ Approval detected for Apple user"
                    )

                    await requestStore
                        .syncFromCloud()

                    let myRequests =
                        requestStore.requests
                            .filter {
                                $0.appleUserID ==
                                    appleUserID
                            }

                    for request in myRequests {

                        requestStore.delete(
                            request
                        )
                    }

                    break
                }

                try? await Task.sleep(
                    for: .seconds(5)
                )
            }
        }
    }

    private var formIsValid:
        Bool {

        !name
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty &&

        !companyName
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty &&

            truckVINLast4
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .count == 4 &&

            !phoneNumber
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
    }

    private func submitRequest() {
        
        denialMessage = nil

        let alreadyPending =
            requestStore.requests.contains {
                $0.appleUserID == appleUserID &&
                $0.status == "pending"
            }

        if alreadyPending {

            submitted = true

            return
        }

        let request =
            UserAccessRequest(
                appleUserID:
                    appleUserID,
                name:
                    name.trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
                companyName:
                    companyName
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                truckVINLast4:
                    truckVINLast4
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .uppercased(),
                phoneNumber:
                    phoneNumber
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
            )

        requestStore.add(
            request
        )

        submitted = true
    }
}

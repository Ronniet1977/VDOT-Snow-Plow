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

    let appleUserID: String

    @State private var name = ""
    @State private var companyName = ""
    @State private var truckVINLast4 = ""

    @State private var submitted = false

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
        }
        .navigationTitle(
            "Request Access"
        )
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
            .count == 4
    }

    private func submitRequest() {

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
                        .uppercased()
            )

        requestStore.add(
            request
        )

        submitted = true
    }
}

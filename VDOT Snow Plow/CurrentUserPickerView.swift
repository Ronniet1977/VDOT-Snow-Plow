//
//  CurrentUserPickerView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import SwiftUI

struct CurrentUserPickerView:
    View {

    @ObservedObject var userStore:
        AppUserStore

    @ObservedObject var currentUserStore:
        CurrentUserStore

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        List {

            ForEach(
                userStore.users
                    .filter {
                        $0.isActive
                    }
            ) { user in

                Button {

                    currentUserStore
                        .select(
                            user
                        )

                    dismiss()

                } label: {

                    HStack {

                        VStack(
                            alignment:
                                .leading,
                            spacing:
                                4
                        ) {

                            Text(
                                user.name
                            )
                            .font(
                                .headline
                            )

                            Text(
                                user.role
                                    .displayName
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )

                            if
                                let category =
                                    user.category {

                                Text(
                                    category
                                        .displayName
                                )
                                .font(
                                    .caption2
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }

                        Spacer()

                        if
                            currentUserStore
                                .currentUserID
                            ==
                            user.id {

                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )
                            .foregroundStyle(
                                .green
                            )
                        }
                    }
                }
                .buttonStyle(
                    .plain
                )
            }
        }
        .navigationTitle(
            "Who Is Using This Device?"
        )
    }
}

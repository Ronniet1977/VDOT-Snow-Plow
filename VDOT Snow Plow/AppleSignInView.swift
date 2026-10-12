//
//  AppleSignInView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/10/26.
//

import SwiftUI
import AuthenticationServices

struct AppleSignInView: View {

    @ObservedObject var requestStore:
        UserAccessRequestStore
    @ObservedObject var appleAccountStore:
        AppleAccountStore
    @ObservedObject var userStore:
        AppUserStore

    @State private var appleUserID:
        String?

    @State private var signInError = ""

    var body: some View {

        NavigationStack {

            VStack(spacing: 24) {

                Spacer()

                Image(
                    systemName:
                        "person.crop.circle.badge.checkmark"
                )
                .font(
                    .system(size: 72)
                )

                Text(
                    "VDOT Snow Plow"
                )
                .font(
                    .largeTitle.bold()
                )

                Text(
                    "Sign in with Apple to request access."
                )
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )

                SignInWithAppleButton(
                    .signIn
                ) { request in

                    request.requestedScopes = [
                        .fullName,
                        .email
                    ]

                } onCompletion: { result in

                    handleSignIn(
                        result
                    )
                }
                .signInWithAppleButtonStyle(
                    .black
                )
                .frame(
                    height: 50
                )

                if !signInError.isEmpty {

                    Text(
                        signInError
                    )
                    .foregroundStyle(
                        .red
                    )
                }

                Spacer()
            }
            .padding()
            .navigationDestination(
                item: $appleUserID
            ) { appleUserID in

                RequestAccessView(
                    requestStore:
                        requestStore,
                    userStore:
                        userStore,
                    appleUserID:
                        appleUserID
                )
            }
        }
    }

    private func handleSignIn(
        _ result:
            Result<
                ASAuthorization,
                Error
            >
    ) {

        switch result {

        case .success(
            let authorization
        ):

            guard let credential =
                authorization.credential
                    as?
                    ASAuthorizationAppleIDCredential
            else {
                return
            }

            appleAccountStore.signIn(
                appleUserID:
                    credential.user
            )

            Task {

                await userStore
                    .syncFromCloud()

                // Already linked to a user
                if appleAccountStore
                    .matchingUser(
                        from: userStore.users
                    ) != nil {

                    return
                }

                // Fresh install:
                // first Apple account claims the default Admin.
                if userStore.users.count == 1,
                   var defaultAdmin =
                    userStore.users.first,
                   defaultAdmin.role == .admin,
                   defaultAdmin.appleUserID == nil {

                    defaultAdmin.appleUserID =
                        credential.user

                    do {

                        try await userStore
                            .saveAndWait(
                                defaultAdmin
                            )

                        print(
                            "👑 Default admin linked to Apple account:",
                            defaultAdmin.name
                        )

                        return

                    } catch {

                        print(
                            "❌ Default admin Apple link failed:",
                            error
                        )
                    }
                }

                // Normal new user:
                // send them to Request Access.
                appleUserID =
                    credential.user
            }

            print(
                "🍎 Apple user ID:",
                credential.user
            )

        case .failure(
            let error
        ):

            signInError =
                error.localizedDescription

            print(
                "❌ Apple sign-in failed:",
                error
            )
        }
    }
}

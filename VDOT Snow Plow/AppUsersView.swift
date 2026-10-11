//
//  AppUsersView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/9/26.
//

import SwiftUI

struct AppUsersView: View {

    @ObservedObject var store:
        AppUserStore
    @ObservedObject var driverStore:
        CrewDriverStore

    @ObservedObject var supervisorStore:
        SupervisorSettingsStore

    @State private var showingAdd =
        false

    @State private var selectedUser:
        AppUser?

    var body: some View {

        List {

            if store.users.isEmpty {

                ContentUnavailableView(
                    "No Users",
                    systemImage:
                        "person.crop.circle.badge.questionmark",
                    description:
                        Text(
                            "Add admins, supervisors, and drivers."
                        )
                )

            } else {

                ForEach(
                    store.users
                ) { user in

                    Button {

                        selectedUser =
                            user

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

                            if user.isActive {

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
                .onDelete { offsets in

                    for index in offsets {

                        store.delete(
                            store.users[index]
                        )
                    }
                }
            }
        }
        .navigationTitle(
            "Users"
        )
        .toolbar {

            ToolbarItem(
                placement:
                    .topBarTrailing
            ) {

                Button {

                    showingAdd =
                        true

                } label: {

                    Image(
                        systemName:
                            "plus"
                    )
                }
            }
        }
        .alert(
            "Admin Required",
            isPresented:
                Binding(
                    get: {
                        store.adminProtectionMessage != nil
                    },
                    set: { newValue in

                        if !newValue {
                            store.adminProtectionMessage =
                                nil
                        }
                    }
                )
        ) {

            Button(
                "OK",
                role: .cancel
            ) {
                store.adminProtectionMessage =
                    nil
            }

        } message: {

            Text(
                store.adminProtectionMessage
                    ?? ""
            )
        }
        .sheet(
            isPresented:
                $showingAdd
        ) {

            AppUserEditView(
                user:
                    AppUser(
                        name: "",
                        role: .driver
                    )
            ) { user in

                store.add(
                    user
                )
            }
        }
        .sheet(
            item:
                $selectedUser
        ) { user in

            AppUserEditView(
                user:
                    user
            ) { changed in

                let syncedUser =
                    UserRoleSyncManager.shared
                        .syncRole(
                            user:
                                changed,
                            oldUser:
                                user,
                            driverStore:
                                driverStore,
                            supervisorStore:
                                supervisorStore
                        )

                store.update(
                    syncedUser
                )
            }
        }
    }
}

private struct AppUserEditView:
    View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var user:
        AppUser
    @State private var adminAlsoDriver =
        false

    let onSave:
        (AppUser) -> Void

    init(
        user: AppUser,
        onSave:
        @escaping
        (AppUser) -> Void
    ) {

        _user =
            State(
                initialValue:
                    user
            )

        _adminAlsoDriver =
            State(
                initialValue:
                    user.role == .admin &&
                    user.driverID != nil
            )

        self.onSave =
            onSave
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("User") {

                    TextField(
                        "Name",
                        text:
                            $user.name
                    )

                    Picker(
                        "Role",
                        selection:
                            $user.role
                    ) {

                        ForEach(
                            AppUserRole.allCases
                        ) { role in

                            Text(
                                role.displayName
                            )
                            .tag(
                                role
                            )
                        }
                    }

                    Toggle(
                        "Active",
                        isOn:
                            $user.isActive
                    )
                }
                
                if user.role == .admin {

                    Section("Driver Access") {

                        Toggle(
                            "Also a Driver",
                            isOn:
                                $adminAlsoDriver
                        )
                    }
                }

                if user.role ==
                    .supervisor {

                    Section(
                        "Supervisor Category"
                    ) {

                        Picker(
                            "Category",
                            selection:
                                Binding(
                                    get: {
                                        user.category
                                            ?? .plowOnly
                                    },
                                    set: {
                                        user.category =
                                            $0
                                    }
                                )
                        ) {

                            ForEach(
                                CrewCategory.allCases
                            ) { category in

                                Text(
                                    category
                                        .displayName
                                )
                                .tag(
                                    category
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle(
                "User"
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {

                    Button(
                        "Cancel"
                    ) {

                        dismiss()
                    }
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {

                    Button(
                        "Save"
                    ) {

                        if user.role
                            != .supervisor {

                            user.category =
                                nil
                        }
                        
                        if user.role == .admin &&
                            adminAlsoDriver == false {

                            user.driverID =
                                nil
                        }

                        onSave(
                            user
                        )

                        dismiss()
                    }
                    .disabled(
                        user.name
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }
}

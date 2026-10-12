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
    @ObservedObject var roleAssignmentStore:
        UserRoleAssignmentStore
    let currentAppleUserID: String?

    @State private var showingAdd =
        false

    @State private var selectedUser:
        AppUser?
    @StateObject private var versionControlStore =
        AppVersionControlStore()

    @State private var showingMinimumBuildConfirmation =
        false

    @State private var versionUpdateMessage:
        String?
    
    private var isDeveloperAccount: Bool {
        currentAppleUserID ==
            "002012.bc49ed6cbbb84a1484cb88d2c9cbeb8f.1919"
    }

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

                    let effectiveUser =
                        roleAssignmentStore
                            .effectiveUser(
                                from: user
                            )

                    Button {

                        selectedUser =
                            effectiveUser

                    } label: {

                        HStack {

                            VStack(
                                alignment:
                                    .leading,
                                spacing:
                                    4
                            ) {

                                Text(
                                    effectiveUser.name
                                )
                                .font(
                                    .headline
                                )

                                Text(
                                    effectiveUser.role
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
                                        effectiveUser.category {

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

                            if effectiveUser.isActive {

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
            
            if isDeveloperAccount {

                Section("Developer") {

                    LabeledContent(
                        "Installed",
                        value:
                            AppVersionInfo.display
                    )

                    LabeledContent(
                        "Required Build",
                        value:
                            "\(versionControlStore.control?.minimumBuild ?? 0)"
                    )

                    Button(
                        "Set Minimum Build to This Build"
                    ) {

                        showingMinimumBuildConfirmation =
                            true
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
        .task {

            await versionControlStore
                .checkVersion()
        }
        .confirmationDialog(
            "Require this build or newer?",
            isPresented:
                $showingMinimumBuildConfirmation,
            titleVisibility:
                .visible
        ) {

            Button(
                "Require Build \(AppVersionInfo.build)",
                role:
                    .destructive
            ) {

                Task {

                    do {

                        try await versionControlStore
                            .setMinimumBuildToCurrent()

                        versionUpdateMessage =
                            "Minimum build is now \(AppVersionInfo.build)."

                    } catch {

                        versionUpdateMessage =
                            "Update failed: \(error.localizedDescription)"
                    }
                }
            }

            Button(
                "Cancel",
                role:
                    .cancel
            ) {}
        }
        .alert(
            "Version Control",
            isPresented:
                Binding(
                    get: {
                        versionUpdateMessage != nil
                    },
                    set: { newValue in

                        if !newValue {
                            versionUpdateMessage =
                                nil
                        }
                    }
                )
        ) {

            Button(
                "OK",
                role:
                    .cancel
            ) {
                versionUpdateMessage =
                    nil
            }

        } message: {

            Text(
                versionUpdateMessage
                ?? ""
            )
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

                Task {

                    do {

                        try await roleAssignmentStore
                            .saveAssignment(
                                for:
                                    syncedUser
                            )

                        print(
                            "✅ Effective role saved:",
                            syncedUser.name
                        )

                    } catch {

                        print(
                            "❌ Effective role save failed:",
                            error
                        )
                    }
                }
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

        self.onSave =
            onSave
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("User") {

                    LabeledContent(
                        "Name",
                        value:
                            user.name
                    )
                    Text(
                        AppVersionInfo.display
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    TextField(
                        "Company Name",
                        text:
                            Binding(
                                get: {
                                    user.companyName ?? ""
                                },
                                set: {
                                    user.companyName = $0
                                }
                            )
                    )

                    TextField(
                        "Phone Number",
                        text:
                            Binding(
                                get: {
                                    user.phoneNumber ?? ""
                                },
                                set: {
                                    user.phoneNumber = $0
                                }
                            )
                    )
                    .keyboardType(
                        .phonePad
                    )

                    TextField(
                        "Truck VIN Last 4",
                        text:
                            Binding(
                                get: {
                                    user.truckVINLast4 ?? ""
                                },
                                set: {
                                    user.truckVINLast4 = $0
                                }
                            )
                    )
                    .textInputAutocapitalization(
                        .characters
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
                
                if user.role == .admin ||
                    user.role == .supervisor {

                    Section("Additional Roles") {

                        Toggle(
                            "Also a Driver",
                            isOn:
                                $user.isAlsoDriver
                        )

                        if user.role == .admin {

                            Toggle(
                                "Also a Supervisor",
                                isOn:
                                    $user.isAlsoSupervisor
                            )
                        }
                    }
                }
                
                if user.role == .supervisor ||
                    (
                        user.role == .admin &&
                        user.isAlsoSupervisor
                    ) {

                    Section("Supervisor Category") {

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

                        if user.role != .supervisor &&
                            !user.isAlsoSupervisor {

                            user.category =
                                nil
                        }
                        
                        if (
                            user.role == .admin ||
                            user.role == .supervisor
                        ) &&
                            user.isAlsoDriver == false {

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

import SwiftUI

struct SupervisorSettingsView: View {

    @ObservedObject var userStore:
        AppUserStore

    var body: some View {

        List {

            ForEach(
                CrewCategory.allCases
            ) { category in

                Section(
                    category.displayName
                ) {

                    let supervisors =
                        supervisors(
                            for: category
                        )

                    if supervisors.isEmpty {

                        Text(
                            "No supervisors"
                        )
                        .foregroundStyle(
                            .secondary
                        )

                    } else {

                        ForEach(
                            supervisors
                        ) { user in

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

                                if user.role == .admin {

                                    Text(
                                        "Admin • Supervisor"
                                    )
                                    .font(
                                        .caption
                                    )
                                    .foregroundStyle(
                                        .secondary
                                    )

                                } else {

                                    Text(
                                        "Supervisor"
                                    )
                                    .font(
                                        .caption
                                    )
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }

                                if let phone =
                                    user.phoneNumber,
                                   !phone.isEmpty {

                                    Text(
                                        phone
                                    )
                                    .font(
                                        .caption
                                    )
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }
                            }
                            .padding(
                                .vertical,
                                2
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(
            "Supervisors"
        )
    }

    private func supervisors(
        for category:
            CrewCategory
    ) -> [AppUser] {

        userStore.users
            .filter { user in

                user.isActive &&

                (
                    user.role == .supervisor ||
                    (
                        user.role == .admin &&
                        user.isAlsoSupervisor
                    )
                ) &&

                user.category == category
            }
            .sorted {

                $0.name
                    .localizedCaseInsensitiveCompare(
                        $1.name
                    )
                ==
                    .orderedAscending
            }
    }
}

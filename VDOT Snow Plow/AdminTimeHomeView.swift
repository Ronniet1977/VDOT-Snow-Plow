import SwiftUI
import CloudKit

struct AdminTimeHomeView: View {
    
    @StateObject private var driverStore =
    CrewDriverStore()
    @StateObject private var supervisorStore =
    SupervisorSettingsStore()
    
    @StateObject private var userStore =
        AppUserStore()
    
    @StateObject private var requestStore =
        UserAccessRequestStore()
    @StateObject private var appleAccountStore =
        AppleAccountStore()
    @StateObject private var reviewRequestStore =
        MapReviewRequestStore()
    @StateObject private var inspectionStore =
        MapReviewInspectionStore()
    @StateObject private var roleAssignmentStore =
        UserRoleAssignmentStore()
    
    private var appleUser: AppUser? {

        guard let baseUser =
            appleAccountStore.matchingUser(
                from: userStore.users
            )
        else {
            return nil
        }

        return roleAssignmentStore
            .effectiveUser(
                from: baseUser
            )
    }
    
    var body: some View {

        Group {

            if let appleUser {

                if appleUser.role == .driver {

                    DriverHomeView(
                        user: appleUser,
                        driverStore: driverStore,
                        appleAccountStore: appleAccountStore
                    )

                } else {

                    adminHome
                }

            } else if let appleUserID =
                        appleAccountStore.appleUserID {

                RequestAccessView(
                    requestStore: requestStore,
                    userStore: userStore,
                    appleUserID: appleUserID
                )

            } else {

                AppleSignInView(
                    requestStore: requestStore,
                    appleAccountStore: appleAccountStore,
                    userStore: userStore
                )
            }
        }
        // main startup task
        .task {

            await driverStore
                .syncFromCloud()

            await supervisorStore
                .syncFromCloud()

            await userStore
                .syncFromCloud()
            
            await roleAssignmentStore
                .syncFromCloud()

            await requestStore
                .syncFromCloud()
            
            await reviewRequestStore
                .syncFromCloud()
            
            await inspectionStore
                .syncFromCloud()
        }
        .task(
            id:
                "\(appleUser?.id.uuidString ?? "none")-\(appleUser?.role.rawValue ?? "none")"
        ) {

            guard let appleUser else {
                return
            }

            await NotificationManager.shared
                .requestPermission()

            if let appleUserID =
                appleUser.appleUserID {

                await NotificationManager.shared
                    .subscribeForUserChanges(
                        appleUserID:
                            appleUserID
                    )
            }
            
            if let appleUserID =
                appleUser.appleUserID {

                await NotificationManager.shared
                    .subscribeForUserRoleAssignments(
                        appleUserID:
                            appleUserID
                    )
            }

            if appleUser.role == .admin {

                await NotificationManager.shared
                    .subscribeForAccessRequests()

                await NotificationManager.shared
                    .subscribeForMapAcknowledgements()

                await NotificationManager.shared
                    .subscribeForMapReviewInspections()

                if let adminDriver {

                    await NotificationManager.shared
                        .subscribeForMapAssignments(
                            driverID:
                                adminDriver.id
                        )
                }
            }

            if appleUser.role == .supervisor ||
                (
                    appleUser.role == .admin &&
                    appleUser.isAlsoSupervisor
                ) {

                await NotificationManager.shared
                    .subscribeForMapReviewRequests()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .accessRequestNotificationReceived
            )
        ) { _ in

            Task {

                print(
                    "🔄 Refreshing access requests after push"
                )

                for attempt in 1...4 {

                    await requestStore
                        .syncFromCloud()

                    if !requestStore.requests.isEmpty {

                        print(
                            "🔴 Access request found on attempt",
                            attempt
                        )

                        break
                    }

                    try? await Task.sleep(
                        for: .seconds(2)
                    )
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for:
                    .userRoleChangedNotificationReceived
            )
        ) { _ in

            Task {

                print(
                    "🔄 Refreshing user after role change"
                )

                let oldRole =
                    appleUser?.role

                for attempt in 1...4 {

                    await userStore
                        .syncFromCloud()

                    if appleUser?.role != oldRole {

                        print(
                            "✅ User role changed on attempt",
                            attempt
                        )

                        break
                    }

                    print(
                        "⏳ Role change not visible yet, attempt",
                        attempt
                    )

                    try? await Task.sleep(
                        for: .seconds(2)
                    )
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for:
                    .mapReviewRequestNotificationReceived
            )
        ) { _ in

            Task {

                print(
                    "🔄 Refreshing supervisor review requests"
                )

                let previousCount =
                    reviewRequestStore
                        .requests
                        .count

                for attempt in 1...4 {

                    await reviewRequestStore
                        .syncFromCloud()

                    if reviewRequestStore
                        .requests
                        .count > previousCount {

                        print(
                            "✅ New map review request found on attempt",
                            attempt
                        )

                        break
                    }

                    print(
                        "⏳ Review request not visible yet, attempt",
                        attempt
                    )

                    try? await Task.sleep(
                        for: .seconds(2)
                    )
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for:
                    .mapReviewInspectionNotificationReceived
            )
        ) { _ in

            Task {

                print(
                    "🔄 Refreshing admin map inspections"
                )

                for attempt in 1...4 {

                    await inspectionStore
                        .syncFromCloud()

                    print(
                        "🔎 Inspection refresh attempt:",
                        attempt,
                        "count:",
                        inspectionStore
                            .inspections
                            .count
                    )

                    if attempt < 4 {

                        try? await Task.sleep(
                            for:
                                .seconds(2)
                        )
                    }
                }

                print(
                    "✅ Admin map inspections refreshed"
                )
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for:
                    .userRoleAssignmentChangedNotificationReceived
            )
        ) { _ in

            Task {

                print(
                    "🔄 Refreshing effective role assignment"
                )

                for attempt in 1...4 {

                    await roleAssignmentStore
                        .syncFromCloud()

                    print(
                        "✅ Role assignment refresh attempt:",
                        attempt
                    )

                    if attempt < 4 {

                        try? await Task.sleep(
                            for: .seconds(2)
                        )
                    }
                }
            }
        }
    }
    
    private var adminDriver: CrewDriver? {

        guard let appleUser,
              appleUser.role == .admin
        else {
            return nil
        }

        return driverStore.drivers.first {
            $0.name.localizedCaseInsensitiveCompare(
                appleUser.name
            ) == .orderedSame
        }
    }
        
    @ViewBuilder
    private var adminHome: some View {

        NavigationStack {

            List {
                
                Section("Time Control") {
                    
                    if appleUser?.role == .admin ||
                        appleUser?.role == .supervisor {
                        
                        NavigationLink {
                            
                            AdminStatusBoardView(
                                driverStore: driverStore,
                                canEdit: appleUser?.role == .admin,
                                supervisorCategory:
                                    appleUser?.role == .supervisor
                                    ? appleUser?.category
                                    : nil,
                                currentUser:
                                    appleUser,
                                userStore:
                                    userStore,
                                roleAssignmentStore:
                                    roleAssignmentStore,
                                inspectionStore:
                                    inspectionStore
                            )
                            
                        } label: {
                            
                            Label(
                                "Status Board",
                                systemImage:
                                    "clock.arrow.circlepath"
                            )
                        }
                    }
                    
                    if let appleUser,
                       (
                            appleUser.role == .admin ||
                            appleUser.role == .supervisor
                       ),
                       appleUser.isAlsoDriver,
                       let driverID = appleUser.driverID,
                       let linkedDriver =
                            driverStore.drivers.first(
                                where: {
                                    $0.id == driverID
                                }
                            ) {

                        NavigationLink {

                            var driverUser = appleUser
                            driverUser.driverID = linkedDriver.id

                            return DriverHomeView(
                                user: driverUser,
                                driverStore: driverStore,
                                appleAccountStore: appleAccountStore
                            )

                        } label: {

                            Label(
                                "Driver View",
                                systemImage: "steeringwheel"
                            )
                        }
                    }
                    
                    if let appleUser,
                       (
                            appleUser.role == .supervisor ||
                            (
                                appleUser.role == .admin &&
                                appleUser.isAlsoSupervisor
                            )
                       ) {

                        NavigationLink {

                            SupervisorMapReviewView(
                                reviewRequestStore:
                                    reviewRequestStore,
                                supervisorUser:
                                    appleUser
                            )

                        } label: {

                            Label(
                                "Pending Map Checks",
                                systemImage:
                                    "checklist"
                            )
                        }
                    }
                }
                
                Section("Crew") {
                    
                    if appleUser?.role == .admin {
                        NavigationLink {

                            CrewDriversView(
                                store:
                                    driverStore
                            )

                        } label: {

                            HStack {

                                Label(
                                    "Drivers",
                                    systemImage:
                                        "person.3"
                                )

                                Spacer()

                                Text(
                                    "\(driverStore.drivers.count)"
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }

                        NavigationLink {

                            SupervisorSettingsView(
                                userStore:
                                    userStore
                            )

                        } label: {

                            Label(
                                "Supervisors",
                                systemImage:
                                    "person.2.badge.gearshape"
                            )
                        }

                        NavigationLink {

                            AppUsersView(
                                store:
                                    userStore,
                                driverStore:
                                    driverStore,
                                supervisorStore:
                                    supervisorStore,
                                roleAssignmentStore:
                                    roleAssignmentStore
                            )

                        } label: {

                            Label(
                                "Users",
                                systemImage:
                                    "person.crop.circle.badge.checkmark"
                            )
                        }
                        
                        NavigationLink {

                            UserAccessRequestsView(
                                requestStore: requestStore,
                                userStore: userStore,
                                driverStore: driverStore,
                                supervisorStore: supervisorStore
                            )

                        } label: {

                            HStack {

                                Label(
                                    "Access Requests",
                                    systemImage:
                                        "person.crop.circle.badge.questionmark"
                                )

                                Spacer()

                                let pendingCount =
                                    requestStore.requests
                                        .filter { request in

                                            request.status == "pending" &&

                                            !userStore.users.contains {
                                                $0.appleUserID ==
                                                    request.appleUserID
                                            }
                                        }
                                        .count

                                if pendingCount > 0 {

                                    Text(
                                        "\(pendingCount)"
                                    )
                                    .font(
                                        .caption.bold()
                                    )
                                    .foregroundStyle(
                                        .white
                                    )
                                    .padding(
                                        .horizontal,
                                        8
                                    )
                                    .padding(
                                        .vertical,
                                        4
                                    )
                                    .background(
                                        Color.red
                                    )
                                    .clipShape(
                                        Capsule()
                                    )
                                }
                            }
                        }
                    }
                    
                    HStack {
                        
                        Text(
                            "Active Drivers"
                        )
                        
                        Spacer()
                        
                        Text(
                            "\(driverStore.drivers.filter { $0.isActive }.count)"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                
                Section("Account") {

                    if let appleUser {

                        HStack {

                            Text("Signed In As")

                            Spacer()

                            Text(appleUser.name)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(
                        "Sign Out",
                        role: .destructive
                    ) {

                        appleAccountStore.signOut()
                    }
                }
            }
            .navigationTitle(
                "Admin Time"
            )
        }
    }
}


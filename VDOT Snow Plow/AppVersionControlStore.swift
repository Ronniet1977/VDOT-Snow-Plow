//
//  AppVersionControlStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation
import Combine

@MainActor
final class AppVersionControlStore:
    ObservableObject {

    @Published var control:
        AppVersionControl?

    @Published var isChecking =
        true

    private let cloud =
        CloudAppVersionControlService.shared

    var currentBuild: Int {

        Int(
            AppVersionInfo.build
        ) ?? 0
    }

    var requiresUpdate: Bool {

        guard let control
        else {
            return false
        }

        return currentBuild <
            control.minimumBuild
    }

    func checkVersion() async {

        isChecking =
            true

        do {

            control =
                try await cloud
                    .fetchControl()

            print(
                "📱 Current build:",
                currentBuild
            )

            print(
                "☁️ Minimum build:",
                control?.minimumBuild
                ?? 0
            )

        } catch {

            print(
                "❌ Version control fetch failed:",
                error
            )
        }

        isChecking =
            false
    }
    
    func setMinimumBuildToCurrent() async throws {

        let build =
            currentBuild

        let control =
            AppVersionControl(
                minimumVersion:
                    AppVersionInfo.version,
                minimumBuild:
                    build,
                message:
                    "Please update VDOT Snow Plow to continue.",
                updatedAt:
                    Date()
            )

        try await cloud
            .saveControl(
                control
            )

        self.control =
            control

        print(
            "✅ Minimum build updated to:",
            build
        )
    }
}

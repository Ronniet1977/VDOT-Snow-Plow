import Foundation
import SwiftUI
import Combine

@MainActor
final class AdminStormStore:
    ObservableObject {

    @Published var storms:
        [Storm] = []

    @Published var activeStormID:
        UUID?

    private let fileName =
        "AdminStorms.json"

    private let activeStormFile =
        "ActiveAdminStorm.json"

    private let cloud =
        CloudAdminStormService.shared

    init() {
        load()
    }

    var activeStorm: Storm? {

        guard let activeStormID else {
            return nil
        }

        return storms.first {
            $0.id == activeStormID
        }
    }

    func load() {

        storms =
            LocalStore.shared.load(
                [Storm].self,
                fileName:
                    fileName,
                defaultValue:
                    []
            )

        activeStormID =
            LocalStore.shared.load(
                UUID?.self,
                fileName:
                    activeStormFile,
                defaultValue:
                    nil
            )
    }

    func save() {

        LocalStore.shared.save(
            storms,
            fileName:
                fileName
        )

        LocalStore.shared.save(
            activeStormID,
            fileName:
                activeStormFile
        )
    }

    func syncFromCloud() async {

        do {

            let cloudStorms =
                try await cloud
                    .fetchStorms()

            storms =
                cloudStorms
                    .map {
                        $0.storm
                    }
                    .sorted {
                        $0.start <
                            $1.start
                    }

            activeStormID =
                cloudStorms
                    .first(
                        where: {
                            $0.isActive
                        }
                    )?
                    .storm
                    .id

            save()

            print(
                "☁️ Admin storms synced:",
                storms.count,
                "| active:",
                activeStormID?
                    .uuidString
                    ?? "none"
            )

        } catch {

            print(
                "❌ Admin storm sync failed:",
                error
            )
        }
    }

    func startStorm(
        name: String
    ) {

        let clean =
            name.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        let storm =
            Storm(
                name:
                    clean.isEmpty
                    ? "Storm \(storms.count + 1)"
                    : clean,
                start:
                    Date()
            )

        storms.append(
            storm
        )

        activeStormID =
            storm.id

        save()

        Task {

            do {

                try await cloud
                    .saveStorm(
                        storm,
                        isActive:
                            true
                    )

                print(
                    "☁️ Admin storm uploaded:",
                    storm.name
                )

            } catch {

                print(
                    "❌ Admin storm upload failed:",
                    error
                )
            }
        }
    }

    func endStorm() {

        guard
            let activeStormID,
            let index =
                storms.firstIndex(
                    where: {
                        $0.id ==
                            activeStormID
                    }
                )
        else {
            return
        }

        storms[index].end =
            Date()

        let finishedStorm =
            storms[index]

        self.activeStormID =
            nil

        save()

        Task {

            do {

                try await cloud
                    .saveStorm(
                        finishedStorm,
                        isActive:
                            false
                    )

                print(
                    "☁️ Admin storm ended:",
                    finishedStorm.name
                )

            } catch {

                print(
                    "❌ Admin storm end upload failed:",
                    error
                )
            }
        }
    }
}

//
//  AppVersionInfo.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

import Foundation

enum AppVersionInfo {

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleShortVersionString"
        ) as? String
        ?? "Unknown"
    }

    static var build: String {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleVersion"
        ) as? String
        ?? "Unknown"
    }

    static var display: String {
        "Version \(version) (Build \(build))"
    }
}

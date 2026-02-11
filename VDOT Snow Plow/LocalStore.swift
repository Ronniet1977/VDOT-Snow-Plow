//
//  LocalStore.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI
import Foundation

final class LocalStore {
    static let shared = LocalStore()
    private init() {}
    
    private func url(for fileName: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }
    
    func load<T: Decodable>(_ type: T.Type, fileName: String, defaultValue: T) -> T {
        let fileURL = url(for: fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return defaultValue }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }
    
    func save<T: Encodable>(_ value: T, fileName: String) {
        let fileURL = url(for: fileName)
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Save failed \(fileName): \(error)")
        }
    }
}

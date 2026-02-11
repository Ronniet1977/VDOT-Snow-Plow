//
//  StormSummaryView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI

struct StormSummaryView: View {
    let summary: TimeViewModel.StormSummary?
    let onExport: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if let s = summary {
                    Text("Storm: \(s.start.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("From \(s.start.formatted(date: .abbreviated, time: .shortened))")
                    Text("To \(s.end.formatted(date: .abbreviated, time: .shortened))")
                        .padding(.bottom, 8)

                    Text("Push: \(s.push, specifier: "%.2f")h")
                    Text("Standby: \(s.standby, specifier: "%.2f")h")
                    Text("Broke: \(s.broke, specifier: "%.2f")h")
                    Divider()
                    Text("Total: \(s.total, specifier: "%.2f")h")
                        .font(.headline)

                    Spacer()

                    Button("Export Timesheet (.xlsx)") { onExport() }
                        .buttonStyle(.borderedProminent)

                } else {
                    Text("No summary available.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

//
//  SettingsView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: TimeViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Timesheet Header Fields") {
                    TextField("Owner Name", text: $vm.ownerName)
                    TextField("Truck #", text: $vm.truckNumber)
                    TextField("Driver Name", text: $vm.driverName)
                    TextField("Event #", text: $vm.eventNumber)
                    TextField("Site Label (e.g., LAKE RIDGE)", text: $vm.siteLabel)
                }
                
                Section {
                    Button("Save Settings") {
                        vm.save()
                    }
                }
                
                Section("Note") {
                    Text("These header fields aren’t in the CSV rows yet. Once you tell me exactly how you want them placed (extra CSV lines, separate file, or a second sheet style), I’ll wire it in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

//
//  MapsView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//
import SwiftUI

struct MapsView: View {
    @EnvironmentObject var vm: TimeViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.maps) { item in
                    NavigationLink {
                        MapEditView(number: item.number)
                            .environmentObject(vm)
                    } label: {
                        HStack {
                            Text("#\(item.number)")
                                .frame(width: 60, alignment: .leading)
                            Text(item.label.isEmpty ? "—" : item.label)
                                .foregroundStyle(item.label.isEmpty ? .secondary : .primary)
                        }
                    }
                }
            }
            .navigationTitle("Maps 1–100")
        }
    }
}

struct MapEditView: View {
    @EnvironmentObject var vm: TimeViewModel
    let number: Int
    
    var body: some View {
        Form {
            Section("Map #\(number)") {
                let binding = Binding<String>(
                    get: { vm.maps.first(where: { $0.number == number })?.label ?? "" },
                    set: { newValue in
                        if let idx = vm.maps.firstIndex(where: { $0.number == number }) {
                            vm.maps[idx].label = newValue
                            vm.save()
                        }
                    }
                )
                TextField("Label (e.g., Walmart Back Lot)", text: binding)
            }
        }
        .navigationTitle("Edit Map")
    }
}

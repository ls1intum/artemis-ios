//
//  File.swift
//  
//
//  Created by Sven Andabaka on 01.03.23.
//

import SwiftUI
import UserStore

struct InstitutionSelectionView: View {

    @Binding var institution: InstitutionIdentifier

    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Text("Please select your university:")
            ForEach(InstitutionIdentifier.allCases) { institutionIdentifier in
                Text(institutionIdentifier.name)
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        institution = institutionIdentifier
                        dismiss()
                    }
            }
        }.listStyle(PlainListStyle())
    }
}

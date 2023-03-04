//
//  File.swift
//  
//
//  Created by Sven Andabaka on 01.03.23.
//

import SwiftUI
import UserStore
import DesignLibrary
import ProfileInfo

struct InstitutionSelectionView: View {

    @Binding var institution: InstitutionIdentifier

    var body: some View {
        List {
            Text("Please select your university:")
                .font(.headline)
            ForEach(InstitutionIdentifier.allCases) { institutionIdentifier in
                Group {
                    if case .custom = institutionIdentifier {
                        CustomInstanceCell(currentInstitution: $institution, institution: institutionIdentifier)
                    } else {
                        InstanceCell(currentInstitution: $institution, institution: institutionIdentifier)
                    }
                }
                    .listRowSeparator(.hidden)
            }
        }
            .listStyle(PlainListStyle())            
    }
}

private struct CustomInstanceCell: View {
    @Environment(\.dismiss) var dismiss

    @Binding var currentInstitution: InstitutionIdentifier

    @State private var customUrl = ""
    @State private var showErrorAlert = false
    @State private var isLoading = false

    var institution: InstitutionIdentifier

    var body: some View {
        VStack {
            HStack {
                InstitutionLogo(institution: institution)
                    .frame(width: .mediumImage)
                Text(institution.name)
                Spacer()
                if currentInstitution == institution {
                    Image(systemName: "checkmark.circle.fill")
                        .frame(width: .smallImage)
                        .foregroundColor(Color.Artemis.artemisBlue)
                }
            }

            TextField("Your Custom Artemis Instance URL", text: $customUrl)
                .textFieldStyle(ArtemisTextField())
                .background(Color.gray.opacity(0.2))
            Button("Select") {
                // TODO: check if valid URL
                guard let url = URL(string: customUrl) else {
                    showErrorAlert = true
                    return
                }
                UserSession.shared.saveInstitution(identifier: .custom(url))

                isLoading = true

                Task {
                    let result = await ProfileInfoServiceFactory.shared.getProfileInfo()
                    isLoading = false
                    switch result {
                    case .loading:
                        isLoading = true
                    case .failure:
                        showErrorAlert = true
                        UserSession.shared.saveInstitution(identifier: .tum)
                    case .done:
                        dismiss()
                    }
                }
            }
                .buttonStyle(ArtemisButton())
                .loadingIndicator(isLoading: $isLoading)
                .alert("The URL is incorrect or does not link to an Artemis instance!", isPresented: $showErrorAlert, actions: { })
        }
            .frame(maxWidth: .infinity)
            .padding(.l)
            .cardModifier()
            .onChange(of: currentInstitution) { newInstitution in
                if case .custom(let url) = institution {
                    customUrl = url?.absoluteString ?? ""
                }
            }.onAppear {
                if case .custom(let url) = currentInstitution {
                    customUrl = url?.absoluteString ?? ""
                }
            }
    }
}

private struct InstanceCell: View {

    @Environment(\.dismiss) var dismiss

    @Binding var currentInstitution: InstitutionIdentifier

    var institution: InstitutionIdentifier

    var body: some View {
        HStack {
            InstitutionLogo(institution: institution)
                .frame(width: .mediumImage)
            Text(institution.name)
            Spacer()
            if currentInstitution == institution {
                Image(systemName: "checkmark.circle.fill")
                    .frame(width: .smallImage)
                    .foregroundColor(Color.Artemis.artemisBlue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.l)
        .cardModifier()
        .onTapGesture {
            UserSession.shared.saveInstitution(identifier: institution)
            dismiss()
        }
    }
}

struct InstitutionLogo: View {

    var institution: InstitutionIdentifier

    var body: some View {
        if institution.logo == nil {
            Image("Artemis-Logo")
                .resizable()
                .scaledToFit()
        } else {
            AsyncImage(url: institution.logo) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image("Artemis-Logo")
                        .resizable()
                        .scaledToFit()
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

extension InstitutionIdentifier {

    var logo: URL? {
        switch self {
        default:
            return URL(string: "public/images/logo.png", relativeTo: self.baseURL)
        }
    }
}

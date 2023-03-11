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

    var handleProfileInfoCompletion: @MainActor (ProfileInfo?) -> Void

    var body: some View {
        List {
            Text(R.string.localizable.account_select_artemis_instance_select_text())
                .font(.headline)
            ForEach(InstitutionIdentifier.allCases) { institutionIdentifier in
                Group {
                    if case .custom = institutionIdentifier {
                        CustomInstanceCell(currentInstitution: $institution,
                                           institution: institutionIdentifier,
                                           handleProfileInfoCompletion: handleProfileInfoCompletion)
                    } else {
                        InstanceCell(currentInstitution: $institution,
                                     institution: institutionIdentifier,
                                     handleProfileInfoCompletion: handleProfileInfoCompletion)
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

    var handleProfileInfoCompletion: @MainActor (ProfileInfo?) -> Void

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

            TextField(R.string.localizable.account_select_artemis_instance_custom_instance(), text: $customUrl)
                .textFieldStyle(ArtemisTextField())
                .background(Color.gray.opacity(0.2))
            Button(R.string.localizable.select()) {
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
                    case .done(let response):
                        handleProfileInfoCompletion(response)
                        dismiss()
                    }
                }
            }
            .buttonStyle(ArtemisButton())
            .loadingIndicator(isLoading: $isLoading)
            .alert(R.string.localizable.account_select_artemis_instance_error(), isPresented: $showErrorAlert, actions: { })
        }
        .frame(maxWidth: .infinity)
        .padding(.l)
        .cardModifier()
        .onChange(of: currentInstitution) { _ in
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

    @State private var showErrorAlert = false
    @State private var isLoading = false

    var institution: InstitutionIdentifier

    var handleProfileInfoCompletion: @MainActor (ProfileInfo?) -> Void

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
        .loadingIndicator(isLoading: $isLoading)
        .alert(R.string.localizable.account_select_artemis_instance_error(), isPresented: $showErrorAlert, actions: { })
        .onTapGesture {
            UserSession.shared.saveInstitution(identifier: institution)
            Task {
                let result = await ProfileInfoServiceFactory.shared.getProfileInfo()
                isLoading = false
                switch result {
                case .loading:
                    isLoading = true
                case .failure:
                    showErrorAlert = true
                    UserSession.shared.saveInstitution(identifier: .tum)
                case .done(let response):
                    handleProfileInfoCompletion(response)
                    dismiss()
                }
            }
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

//
//  ProfilePictureView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 11.09.24.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct ProfilePictureView: View {
    let user: ConversationUser

    var body: some View {
        Group {
            if let url = user.imagePath {
                ArtemisAsyncImage(imageURL: url) {
                    defaultProfilePicture
                }
            } else {
                defaultProfilePicture
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(.rect(cornerRadius: .m))
    }

    @ViewBuilder var defaultProfilePicture: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
            Text(initials)
                .font(.headline.bold())
                .fontDesign(.rounded)
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var initials: String {
        let nameComponents = user.name?.split(separator: " ")
        let initialFirstName = nameComponents?.first?.prefix(1) ?? ""
        let initialLastName = nameComponents?.last?.prefix(1) ?? ""
        let initials = initialFirstName + initialLastName
        if initials.isEmpty {
            return "NA"
        } else {
            return String(initials)
        }
    }

    private var backgroundColor: Color {
        let hash = abs(String(user.id).hashValue) % 255
        return Color(hue: Double(hash) / 255, saturation: 0.5, brightness: 0.5)
    }
}
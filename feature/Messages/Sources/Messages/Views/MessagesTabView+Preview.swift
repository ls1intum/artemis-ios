//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 10.10.23.
//

import Dependencies
import SharedModels
import SwiftUI

#Preview {
    ZStack {
        NavigationStack {
            MessagesTabView(viewModel: withDependencies({ values in
                values.messagesService = MessagesServiceStub()
            }, operation: {
                MessagesTabViewModel(course: Course(
                    id: 1,
                    courseInformationSharingConfiguration: .messagingOnly))
            }), searchText: .constant(""))
            .navigationTitle("Advanced Aerospace Engineering 🚀")
            .navigationBarTitleDisplayMode(.inline)
        }


        GeometryReader { proxy in
            Image("uhr", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(alignment: .center)
                .clipped()
                .clipped()
                .mask(            
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.clear,
                            Color.clear,
                            Color.black,
                        ],
                        startPoint: .top,
                        endPoint: .bottom)
                )
        }
        .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Communicate with students and instructors")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
                .background {
                    RoundedRectangle(
                        cornerRadius: 25.0,
                        style: .continuous)
                    .foregroundStyle(Color(
                        red: 213/256, green: 241/256, blue: 255/256))
                }
                .padding()
        }
        .ignoresSafeArea()
    }
}

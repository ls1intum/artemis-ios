//
//  SwiftUIView.swift
//
//
//  Created by Sven Andabaka on 26.01.23.
//

import SwiftUI

public struct DataStateView<T, Content: View>: View {
    @Binding var data: DataState<T>
    var content: (T) -> Content
    var retryHandler: () async -> Void

    public init(data: Binding<DataState<T>>,
                retryHandler: @escaping () async -> Void,
                @ViewBuilder content: @escaping (T) -> Content) {
        self._data = data
        self.retryHandler = retryHandler
        self.content = content
    }

    public var body: some View {
        Group {
            switch data {
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .failure(let error):
                VStack(spacing: 8) {
                    Spacer()
                    Text(error.title)
                        .font(.title)
                        .foregroundColor(.red)
                    if let message = error.message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    if let detail = error.detail {
                        Text(detail)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    Button("Retry") {
                        Task {
                            await retryHandler()
                        }
                    }
                    Spacer()
                }
            case .done(let result):
                if let content = content {
                    content(result)
                } else {
                    Text("An error occured")
                }
            }
        }
    }
}

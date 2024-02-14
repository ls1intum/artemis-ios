//
//  Badge.swift
//
//
//  Created by Nityananda Zbil on 10.11.23.
//

import DesignLibrary
import SwiftUI

struct Badge: View {
    let count: Int

    var body: some View {
        // swiftlint:disable:next empty_count
        if count > 0 {
            Text("\(count)")
                .font(.body.bold().monospacedDigit())
                .foregroundColor(.white)
                .padding(.vertical, .xs)
                .padding(.horizontal, .m)
                .background {
                    Capsule()
                        .fill(.red)
                }
        }
    }
}

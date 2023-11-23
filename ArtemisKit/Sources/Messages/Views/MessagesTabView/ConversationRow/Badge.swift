//
//  Badge.swift
//
//
//  Created by Nityananda Zbil on 10.11.23.
//

import SwiftUI

struct Badge: View {
    let unreadCount: Int

    var body: some View {
        if unreadCount > 0 {
            Text("\(unreadCount)")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.m)
                .background(.red)
                .clipShape(Circle())
        } else {
            EmptyView()
        }
    }
}

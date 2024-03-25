//
//  SendMessageViewModelDelegate.swift
//
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import SwiftUI

@MainActor
struct SendMessageViewModelDelegate {
    let presentError: (UserFacingError) -> Void
    let sendMessage: (String) async -> Void
}

//
//  MessagesPreferences.swift
//
//
//  Created by Nityananda Zbil on 17.10.23.
//

import SwiftUI

/// `MessagesPreferences` is an environment object that signals preferences from `MessagesTabView` to its container view.
///
/// Unfortunately, the `.preference(key:value:)` modifier did not update the value correctly at the container view.
public class MessagesPreferences: ObservableObject {
    /// `isSearchable` signals if the `MessagesTabView` is searchable.
    @Published public internal(set) var isSearchable = false

    public init() {}
}

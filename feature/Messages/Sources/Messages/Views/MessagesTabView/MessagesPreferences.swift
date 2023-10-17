//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 17.10.23.
//

import SwiftUI

/// `MessagesPreferences` is an environment object that signals preferences from subviews to its container view.
public class MessagesPreferences: ObservableObject {
    /// `isSearchable` signals if the subview is searchable.
    @Published public internal(set) var isSearchable = true

    public init() {}
}

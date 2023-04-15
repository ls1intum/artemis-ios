//
//  BaseViewModel.swift
//  
//
//  Created by Sven Andabaka on 12.04.23.
//

import Foundation
import SwiftUI

@MainActor
open class BaseViewModel: ObservableObject {

    @Published public private(set) var error: UserFacingError? {
        didSet {
            showError = error != nil
        }
    }
    @Published public var showError = false

    @Published public var isLoading = false

    public init() { }

    public func presentError(userFacingError: UserFacingError) {
        error = userFacingError
    }
}

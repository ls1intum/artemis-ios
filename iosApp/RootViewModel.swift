//
//  RootViewModel.swift
//  Artemis
//
//  Created by Sven Andabaka on 12.01.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Foundation
import Combine
import UserStore
import SwiftUI

class RootViewModel: ObservableObject {
    
    @Published var isLoggedIn = false
    @Published var path = NavigationPath()

    private var cancellables: Set<AnyCancellable> = Set()
    
    init() {
        UserSession.shared.objectWillChange.sink {
            DispatchQueue.main.async { [unowned self] in
                self.isLoggedIn = UserSession.shared.bearerToken != nil
            }
        }.store(in: &cancellables)
        
        path.appendDashboard()
    }
}

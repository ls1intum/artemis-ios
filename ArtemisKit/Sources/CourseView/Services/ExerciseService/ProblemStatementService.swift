//
//  ProblemStatementService.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.04.26.
//

import Common
import Foundation
import SharedModels

protocol ProblemStatementService {
    func getRenderedProblemStatement(for markdown: String, darkMode: Bool) async -> DataState<String>
}

enum ProblemStatementServiceFactory {
    static let shared: ProblemStatementService = ProblemStatementServiceImpl()
}

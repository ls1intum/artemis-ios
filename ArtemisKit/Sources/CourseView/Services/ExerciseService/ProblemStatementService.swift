//
//  ProblemStatementService.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.04.26.
//

import Foundation

import Foundation
import Common
import SharedModels

protocol ProblemStatementService {
    func getRenderedProblemStatement(for markdown: String) async -> DataState<String>
}

enum ProblemStatementServiceFactory {
    static let shared: ProblemStatementService = ProblemStatementServiceImpl()
}

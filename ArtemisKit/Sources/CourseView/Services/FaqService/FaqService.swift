//
//  FaqService.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import Common
import SharedModels

protocol FaqService {
    func getFaqs(for courseId: Int) async -> DataState<[FaqDTO]>
}

enum FaqServiceFactory {
    static let shared: FaqService = FaqServiceImpl()
}

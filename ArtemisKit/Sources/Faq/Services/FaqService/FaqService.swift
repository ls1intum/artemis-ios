//
//  FaqService.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import Common
import SharedModels

public protocol FaqService {
    func getFaqs(for courseId: Int) async -> DataState<[FaqDTO]>
    func getFaq(with faqId: Int64, for courseId: Int) async -> DataState<FaqDTO>
}

public enum FaqServiceFactory {
    public static let shared: FaqService = FaqServiceImpl()
}

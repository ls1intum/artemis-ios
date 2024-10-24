//
//  FaqViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import Common
import Foundation
import SharedModels

@Observable
class FaqViewModel {
    let course: Course

    private let faqService = FaqServiceFactory.shared
    var faqs: DataState<[FaqDTO]> = .loading

    var searchText = ""

    init(course: Course) {
        self.course = course
    }

    func loadFaq() async {
        faqs = await faqService.getFaqs(for: course.id)
    }
}

// MARK: FAQ+Search
extension FaqViewModel {
    var searchResults: [FaqDTO] {
        faqs.value?.filter {
            $0.questionTitle.localizedStandardContains(searchText) ||
            $0.questionAnswer.localizedStandardContains(searchText)
        } ?? []
    }
}

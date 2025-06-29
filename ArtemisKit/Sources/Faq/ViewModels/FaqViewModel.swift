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

    var proposedFaq = FaqDTO()
    var showProposalView = false
    var isLoading = false
    var error: UserFacingError?
    var canPropose: Bool {
        course.isAtLeastTutorInCourse
    }

    init(course: Course) {
        self.course = course
    }

    func loadFaq() async {
        let allFaqs = await faqService.getFaqs(for: course.id)
        switch allFaqs {
        case .loading:
            faqs = .loading
        case .failure(let error):
            faqs = .failure(error: error)
        case .done(let response):
            if canPropose {
                faqs = .done(response: response.filter { $0.faqState != .rejected })
            } else {
                faqs = .done(response: response.filter { $0.faqState == .accepted })
            }
        }
    }

    func proposeFaq() async {
        isLoading = true
        defer {
            isLoading = false
        }

        let createdFaq = await faqService.proposeFaq(faq: proposedFaq, for: course.id)
        switch createdFaq {
        case .failure(let error):
            self.error = error
        case .done(let response):
            faqs.value?.append(response)
            showProposalView = false
        default:
            break
        }
    }
}

// MARK: FAQ+Search
extension FaqViewModel {
    var searchResults: [FaqDTO] {
        faqs.value?.filter {
            $0.questionTitle.localizedStandardContains(searchText) ||
            $0.questionAnswer.localizedStandardContains(searchText) ||
            $0.categories?.map(\.category).contains(where: { $0.localizedStandardContains(searchText) }) == true
        } ?? []
    }
}

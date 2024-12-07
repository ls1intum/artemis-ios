//
//  SendMessageFAQPickerViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 04.12.24.
//

import Faq
import SharedModels
import SwiftUI

@Observable
final class SendMessageFAQPickerViewModel {

    let course: Course
    var faqs: [FaqDTO]

    private let delegate: SendMessageMentionContentDelegate
    private let faqService: FaqService

    init(
        course: Course,
        faqs: [FaqDTO] = [],
        delegate: SendMessageMentionContentDelegate = SendMessageMentionContentDelegate { _ in },
        faqService: FaqService = FaqServiceFactory.shared
    ) {
        self.course = course
        self.faqs = faqs
        self.delegate = delegate
        self.faqService = faqService
    }

    func loadFAQs() async {
        let faqs = await faqService.getFaqs(for: course.id)

        if case let .done(faqs) = faqs {
            self.faqs = faqs
        }
    }

    func select(faq: FaqDTO) {
        delegate.pickerDidSelect("[faq]\(faq.questionTitle)(/courses/\(course.id)/faq?faqId=\(faq.id))[/faq]")
    }
}

//
//  PathViewModels.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import Common
import Foundation
import SharedModels

@Observable
final class FaqPathViewModel {
    let path: FaqPath
    var faq: DataState<FaqDTO>

    init(path: FaqPath) {
        self.path = path
        self.faq = path.faq.map(DataState.done) ?? .loading
    }

    func loadFaq() async {
        faq = await FaqServiceFactory.shared.getFaq(with: path.id, for: path.courseId ?? 0)
    }
}

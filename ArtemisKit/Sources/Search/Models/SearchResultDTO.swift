//
//  SearchResultDTO.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import Foundation
import Navigation

struct SearchResultDTO: Decodable {
    let id: String?
    let type: SearchFilterType?
    let title: String?
    let description: String?
    let badge: String?
    let metadata: (any SearchResultDetails)?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.type = try container.decodeIfPresent(SearchFilterType.self, forKey: .type)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.badge = try container.decodeIfPresent(String.self, forKey: .badge)
        if let type, let decodable = type.codableType {
            self.metadata = try container.decodeIfPresent(decodable, forKey: .metadata)
        } else {
            self.metadata = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, title, description, badge, metadata
    }
}

extension SearchResultDTO {
    func navigate(with controller: NavigationController) async {
        await metadata?.navigateToDetail(with: controller, result: self)
    }
}

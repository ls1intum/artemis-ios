//
//  SearchResultDetails.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.03.26.
//

import Foundation
import Navigation
import SwiftUI

protocol SearchResultDetails: Decodable {
    var courseId: Int? { get }
    var courseName: String? { get }

    var displayInfo: [Text] { get }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async
}

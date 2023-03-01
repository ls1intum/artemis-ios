//
//  PushNotification.swift
//  Artemis
//
//  Created by Sven Andabaka on 19.02.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Foundation

struct PushNotification: Codable {
    var title: String
    var body: String
    var target: String
}

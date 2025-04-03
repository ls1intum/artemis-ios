//
//  TappableNotification.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 26.03.25.
//

import Navigation

protocol TappableNotification {
    func handleTap(with navController: NavigationController) async
}

//
//  ResultMetadataView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.03.26.
//

import SwiftUI

struct ResultMetadataView: View {
    let details: any SearchResultDetails

    var body: some View {
        if let name = details.courseName {
            Label(name, systemImage: "list.bullet.rectangle.fill")
        }
        
        details.displayInfo.reduce(Text("")) { partialResult, text in
            partialResult + Text(" • ") + text
        }
    }
}

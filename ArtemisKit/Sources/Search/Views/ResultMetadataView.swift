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
        let name = details.courseName ?? ""
        let image = Image(systemName: "list.bullet.rectangle.fill")

        details.displayInfo.reduce(Text("\(image)\u{00A0}\(name)")) { partialResult, text in
            partialResult + Text(" • ") + text
        }
    }
}

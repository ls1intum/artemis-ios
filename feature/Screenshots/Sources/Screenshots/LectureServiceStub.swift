//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 10.10.23.
//

import Common
import Dependencies
import Foundation
import SharedModels
@testable import CourseView

struct LectureServiceStub: LectureService {

    private static let lecture = Lecture(
        id: 1,
        title: "Lecture 7 - Rocket Fuel ⛽",
        description: "In this lecture, you will learn about the most important types of rocket fuel.",
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
        endDate: Calendar.current.date(byAdding: .day, value: 1, to: .now),
        attachments: [
            .file(attachment: FileAttachment(
                id: 1,
                name: "Monopropellants",
                version: 3,
                uploadDate: Calendar.current.date(byAdding: .month, value: -1, to: .now))),
        ],
        lectureUnits: [
            .text(lectureUnit: TextUnit(
                id: 1,
                name: "Introduction to Fuel Types",
                visibleToStudents: true,
                content: """
                Multiple types of rocket propellants exist. Each of them has their own advantages and disadvantages.
                1. Solid chemical propellants
                2. Liquid chemical propellants
                3. Hybrid propellants
                """
            )),
            .text(lectureUnit: TextUnit(
                id: 2,
                name: "Solid Chemical Propellants",
                content: """
                Solid chemical propellants are a fundamental component of rocket engines, offering simplicity and reliability in space exploration.
                Comprising a mixture of fuel and oxidizer tightly packed into a solid form, these propellants provide thrust by controlled combustion.
                Their sturdiness and efficiency make them a vital choice for various rocket applications.
                """
            )),
        ])

    func getLectureDetails(lectureId: Int) async -> Common.DataState<SharedModels.Lecture> {
        .done(response: Self.lecture)
    }
    
    func getAttachmentFile(link: String) async -> Common.DataState<URL> {
        .loading
    }
    
    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> Common.NetworkResponse {
        .loading
    }
}

//
//  File.swift
//
//
//  Created by Sven Andabaka on 15.01.23.
//

import Foundation
import SharedModels

final class ParticipationServiceImpl: ParticipationService {

    func getLatestPendingSubmissionByParticipationIdObservable(participationId: Int, exerciseId: Int, personal: Bool, fetchPending: Bool) -> ProgrammingSubmissionStateData? {
        // TODO:
        return nil
    }

    func subscribeForParticipationChanges() -> StudentParticipation? {
        return nil
    }
}

//
//  IrisContextSwitchDivider.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import DesignLibrary
import Navigation
import SwiftUI

struct IrisContextSwitchDivider: View {
    let info: IrisContextSwitchAttributes
    let courseId: Int

    @EnvironmentObject private var navigationController: NavigationController

    private enum NavigationTarget {
        case exercise(Int)
        case lecture(Int)
    }

    var body: some View {
        HStack(spacing: .m) {
            line
            Group {
                if let target = navigationTarget {
                    Button {
                        navigate(to: target)
                    } label: {
                        chip
                    }
                    .buttonStyle(.plain)
                } else {
                    chip
                }
            }
            .foregroundStyle(Color.Artemis.artemisBlue)
            .layoutPriority(1)
            line
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .s)
    }

    private var chip: some View {
        HStack(spacing: .s) {
            if info.transition != .removed, let icon = info.entityMode?.icon {
                Image(systemName: icon)
                    .imageScale(.small)
            }
            Text(label)
                .font(.caption)
                .lineLimit(1)
        }
    }

    private var line: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(height: 1)
    }

    private var navigationTarget: NavigationTarget? {
        guard info.transition != .removed, let entityId = info.entityId else {
            return nil
        }
        switch info.entityMode {
        case .lecture:
            return .lecture(entityId)
        case .textExercise, .programmingExercise:
            return .exercise(entityId)
        default:
            return nil
        }
    }

    private func navigate(to target: NavigationTarget) {
        switch target {
        case .exercise(let id):
            navigationController.goToExercise(courseId: courseId, exerciseId: id)
        case .lecture(let id):
            navigationController.goToLecture(courseId: courseId, lectureId: id)
        }
    }

    private var label: String {
        switch info.transition {
        case .removed:
            return R.string.localizable.contextRemoved()
        case .changed:
            return R.string.localizable.contextSwitched(info.name ?? "")
        case .added, .unknown:
            return R.string.localizable.contextAdded(info.name ?? "")
        }
    }
}

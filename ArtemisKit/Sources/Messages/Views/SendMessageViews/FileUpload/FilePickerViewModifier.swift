//
//  FilePickerViewModifier.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.12.24.
//

import SwiftUI

extension View {
    /// Add this further up in the view hierarchy to use a file picker somewhere below
    func supportsFilePicker() -> some View {
        modifier(AddFilePickerViewModifier())
    }

    /// Use this to utitlize the previously added file picker
    func filePicker(isPresented: Binding<Bool>,
                    onFilePicked: @escaping (URL) -> Void,
                    onError: @escaping (Error) -> Void) -> some View {
        modifier(UseFilePickerViewModifier(presentFilePicker: isPresented,
                                           onFilePick: onFilePicked,
                                           onError: onError))
    }
}

/// Adds a fileImporter in the view hierarchy for use in lower levels.
/// Use this before you can use `.filePicker` on a View.
private struct AddFilePickerViewModifier: ViewModifier {
    @State var manager = FilePickerManager()
    func body(content: Content) -> some View {
        @Bindable var manager = manager

        content
            .environment(\.filePickerManager, manager)
            .fileImporter(isPresented: $manager.isPresented,
                          allowedContentTypes: [.pdf],
                          allowsMultipleSelection: false) { result in
                switch result {
                case .success(let success):
                    if let url = success.first {
                        manager.onPicked(url)
                    }
                case .failure(let failure):
                    manager.onError(failure)
                }
            }
    }
}

/// This uses the previously injected fileImporter.
/// *Prerequesite*: Use `.supportsFilePicker()` on a view further up
private struct UseFilePickerViewModifier: ViewModifier {
    @Environment(\.filePickerManager) var manager

    @Binding var presentFilePicker: Bool
    let onFilePick: (URL) -> Void
    let onError: (Error) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: presentFilePicker, initial: true) { _, newValue in
                manager.isPresented = newValue
            }
            .onAppear {
                manager.onPicked = onFilePick
                manager.onError = onError
            }
    }
}

@Observable
class FilePickerManager {
    var isPresented = false
    var onPicked: (URL) -> Void = { _ in }
    var onError: (Error) -> Void = { _ in }
}

private enum FilePickerManagerKey: EnvironmentKey {
    static let defaultValue = FilePickerManager()
}

private extension EnvironmentValues {
    var filePickerManager: FilePickerManager {
        get {
            self[FilePickerManagerKey.self]
        }
        set {
            self[FilePickerManagerKey.self] = newValue
        }
    }
}

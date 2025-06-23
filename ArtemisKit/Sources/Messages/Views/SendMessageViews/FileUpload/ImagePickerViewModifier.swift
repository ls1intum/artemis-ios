//
//  ImagePickerViewModifier.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.06.25.
//

import PhotosUI
import SwiftUI

public extension View {
    /// Add this further up in the view hierarchy to use an image picker somewhere below
    func supportsImagePicker() -> some View {
        modifier(AddImagePickerViewModifier())
    }

    /// Use this to utitlize the previously added image picker
    func imagePicker(isPresented: Binding<Bool>,
                     selectedImage: Binding<PhotosPickerItem?>) -> some View {
        modifier(UseImagePickerViewModifier(presentImagePicker: isPresented,
                                            selectedImage: selectedImage))
    }
}

/// Adds a photoPicker in the view hierarchy for use in lower levels.
/// Use this before you can use `.imagePicker` on a View.
private struct AddImagePickerViewModifier: ViewModifier {
    @State var manager = ImagePickerManager()
    func body(content: Content) -> some View {
        @Bindable var manager = manager

        content
            .environment(\.imagePickerManager, manager)
            .photosPicker(isPresented: manager.isPresented, selection: manager.selectedItem, matching: .images, preferredItemEncoding: .compatible)
    }
}

/// This uses the previously injected photoPicker.
/// *Prerequesite*: Use `.supportsImagePicker()` on a view further up
private struct UseImagePickerViewModifier: ViewModifier {
    @Environment(\.imagePickerManager) var manager

    @Binding var presentImagePicker: Bool
    @Binding var selectedImage: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .onAppear {
                manager.isPresented = _presentImagePicker
                manager.selectedItem = _selectedImage
            }
    }
}

@Observable
class ImagePickerManager {
    var isPresented: Binding<Bool> = .constant(false)
    var selectedItem: Binding<PhotosPickerItem?> = .constant(nil)
}

private enum ImagePickerManagerKey: EnvironmentKey {
    static let defaultValue = ImagePickerManager()
}

private extension EnvironmentValues {
    var imagePickerManager: ImagePickerManager {
        get {
            self[ImagePickerManagerKey.self]
        }
        set {
            self[ImagePickerManagerKey.self] = newValue
        }
    }
}

import SwiftUI
import PDFKit

struct LecturePDFReader: View {
    let url: URL
    let explicitPage: Int?
    let progress: LectureMediaProgress?
    var requiresExactPage = false
    @State private var document: PDFDocument?
    @State private var page = 0
    @State private var loaded = false
    @State private var targetUnavailable = false

    var body: some View {
        Group {
            if let document, document.pageCount > 0 {
                VStack(spacing: 0) {
                    LecturePDFView(document: document, page: $page)
                    Divider()
                    Stepper(value: $page, in: 0...(document.pageCount - 1)) {
                        Text("Page \(page + 1) of \(document.pageCount)")
                            .monospacedDigit()
                    }
                    .padding()
                    .accessibilityLabel("PDF page")
                    .accessibilityValue("\(page + 1) of \(document.pageCount)")
                }
            } else if loaded {
                ContentUnavailableView(targetUnavailable ? "Referenced slide is unavailable" : "PDF could not be opened", systemImage: "doc.questionmark", description: Text(targetUnavailable ? "This slide is not present in the available PDF. Export the file or return to the lecture." : "Export the file to try another app."))
            } else {
                ProgressView("Opening PDF…")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: url) { Label("Share", systemImage: "square.and.arrow.up") }
            }
        }
        .task {
            guard !loaded else { return }
            document = PDFDocument(url: url)
            let count = document?.pageCount ?? 0
            if requiresExactPage, let explicitPage, LectureMediaSlidePage.documentIndex(page: explicitPage, pageCount: count) == nil {
                targetUnavailable = true
                document = nil
                loaded = true
                return
            }
            page = progress?.pageIndex(explicitPage: explicitPage, pageCount: count)
                ?? min(max(0, (explicitPage ?? 1) <= 1 ? 0 : (explicitPage ?? 1) - 1), max(0, count - 1))
            loaded = true
        }
        .onChange(of: page) { _, value in progress?.save(page: value) }
        .onDisappear { progress?.save(page: page) }
    }
}

private struct LecturePDFView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var page: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemBackground
        view.document = document
        if let target = document.page(at: page) { view.go(to: target) }
        context.coordinator.observe(view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.parent = self
        guard let target = document.page(at: page), view.currentPage != target else { return }
        view.go(to: target)
    }

    final class Coordinator: NSObject {
        var parent: LecturePDFView
        private var observer: NSObjectProtocol?
        init(_ parent: LecturePDFView) { self.parent = parent }
        func observe(_ view: PDFView) {
            observer = NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: view, queue: .main) { [weak self, weak view] _ in
                guard let self, let current = view?.currentPage else { return }
                let index = self.parent.document.index(for: current)
                guard index != NSNotFound, self.parent.page != index else { return }
                self.parent.page = index
            }
        }
        deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    }
}

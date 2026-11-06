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
    @State private var restorationError = false
    @State private var readerGeneration = UUID()

    var body: some View {
        Group {
            if restorationError {
                ContentUnavailableView {
                    Label("Reading position could not be restored", systemImage: "doc.questionmark")
                } description: {
                    Text("Try again, or export the PDF to another app.")
                } actions: {
                    Button("Retry") { readerGeneration = UUID(); restorationError = false }
                }
            } else if let document, document.pageCount > 0 {
                VStack(spacing: 0) {
                    LecturePDFView(document: document, page: $page, onRestoreFailure: { restorationError = true })
                        .id(readerGeneration)
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
                let title = targetUnavailable ? "Referenced slide is unavailable" : "PDF could not be opened"
                let message = targetUnavailable
                    ? "This slide is not present in the available PDF. Export the file or return to the lecture."
                    : "Export the file to try another app."
                ContentUnavailableView(title, systemImage: "doc.questionmark", description: Text(message))
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
            if document?.isLocked == true { document = nil }
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
        .onChange(of: page) { _, value in
            if loaded, document != nil, !restorationError { progress?.save(page: value) }
        }
        .onDisappear {
            if loaded, document != nil, !restorationError { progress?.save(page: page) }
        }
    }
}

private struct LecturePDFView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var page: Int
    let onRestoreFailure: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> LectureReadingPDFView {
        let view = LectureReadingPDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemBackground
        context.coordinator.attach(view)
        view.document = document
        context.coordinator.request(page, in: view)
        return view
    }

    func updateUIView(_ view: LectureReadingPDFView, context: Context) {
        context.coordinator.parent = self
        if view.document !== document {
            context.coordinator.beginRestoration(to: page)
            view.document = document
        }
        context.coordinator.request(page, in: view)
    }

    static func dismantleUIView(_ view: LectureReadingPDFView, coordinator: Coordinator) {
        coordinator.stop()
        view.willLayout = nil; view.didLayout = nil
        view.document = nil
    }

    final class Coordinator: NSObject {
        var parent: LecturePDFView
        private var observer: NSObjectProtocol?
        private weak var readingView: LectureReadingPDFView?
        private var desiredPage: Int
        private var lastSize = CGSize.zero
        private var restoring = true
        private var scheduled = false
        private var active = true
        private var attempts = 0
        private var restorationID = UUID()

        init(_ parent: LecturePDFView) { self.parent = parent; desiredPage = parent.page }

        func attach(_ view: LectureReadingPDFView) {
            readingView = view
            // A gesture during deferred placement would be discarded by the restore gate.
            view.isUserInteractionEnabled = false
            view.willLayout = { [weak self, weak view] in
                guard let self, let view, self.active, view.bounds.size != self.lastSize else { return }
                // PDFKit can emit page zero while rebuilding its document view.
                // Gate those notifications before calling super.layoutSubviews.
                self.beginRestoration(to: self.parent.page)
                self.lastSize = view.bounds.size
            }
            view.didLayout = { [weak self, weak view] in
                if let view { self?.restoreAfterLayout(view) }
            }
            observer = NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: view, queue: .main) { [weak self, weak view] _ in
                guard let self, let view, self.active else { return }
                guard view.bounds.size == self.lastSize else {
                    self.beginRestoration(to: self.parent.page)
                    view.setNeedsLayout()
                    return
                }
                guard !self.restoring, view.document === self.parent.document,
                      let current = view.currentPage else { return }
                let index = self.parent.document.index(for: current)
                guard index != NSNotFound else { return }
                self.desiredPage = index
                if self.parent.page != index { self.parent.page = index }
            }
        }

        func beginRestoration(to page: Int) {
            desiredPage = page
            readingView?.isUserInteractionEnabled = false
            restoring = true; scheduled = false; attempts = 0
            restorationID = UUID()
        }

        func request(_ page: Int, in view: LectureReadingPDFView) {
            if page != desiredPage { beginRestoration(to: page) }
            if restoring { view.setNeedsLayout() }
        }

        private func restoreAfterLayout(_ view: LectureReadingPDFView) {
            guard active, restoring, !scheduled, view.bounds.width > 0, view.bounds.height > 0 else { return }
            scheduled = true
            let request = restorationID
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view, self.active, self.restorationID == request else { return }
                guard view.bounds.size == self.lastSize else { self.scheduled = false; view.setNeedsLayout(); return }
                view.layoutDocumentView()
                guard let target = self.parent.document.page(at: self.desiredPage) else {
                    self.stop(); self.parent.onRestoreFailure(); return
                }
                view.go(to: target)
                // Allow PDFKit's deferred initial/rotation layout to finish before
                // accepting reading notifications or persisting its current page.
                DispatchQueue.main.async { [weak self, weak view] in
                    guard let self, let view, self.active, self.restorationID == request else { return }
                    self.scheduled = false
                    if let current = view.currentPage, self.parent.document.index(for: current) == self.desiredPage {
                        self.restoring = false
                        view.isUserInteractionEnabled = true
                    } else {
                        self.attempts += 1
                        if self.attempts < 5 { view.setNeedsLayout(); view.layoutIfNeeded() } else { self.stop(); self.parent.onRestoreFailure() }
                    }
                }
            }
        }

        func stop() {
            readingView?.isUserInteractionEnabled = false
            active = false; restorationID = UUID(); scheduled = false
            if let observer { NotificationCenter.default.removeObserver(observer) }
            observer = nil
        }
        deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    }
}

private final class LectureReadingPDFView: PDFView {
    var willLayout: (() -> Void)?
    var didLayout: (() -> Void)?
    override func layoutSubviews() {
        willLayout?()
        super.layoutSubviews()
        didLayout?()
    }
}

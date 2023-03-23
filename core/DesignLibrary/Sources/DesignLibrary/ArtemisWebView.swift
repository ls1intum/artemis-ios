//
//  ArtemisWebView.swift
//  
//
//  Created by Sven Andabaka on 23.03.23.
//

import SwiftUI
import WebKit

public struct ArtemisWebView: UIViewRepresentable {

    @Binding var urlRequest: URLRequest
    @Binding var contentHeight: CGFloat

    public init(urlRequest: Binding<URLRequest>, contentHeight: Binding<CGFloat>) {
        self._urlRequest = urlRequest
        self._contentHeight = contentHeight
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        if let cookie = URLSession.shared.authenticationCookie?.first {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
        // TODO: this does not supress the warning
        DispatchQueue.main.async {
            webView.load(urlRequest)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var contentHeight: CGFloat

        init(contentHeight: Binding<CGFloat>) {
            self._contentHeight = contentHeight
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                webView.evaluateJavaScript("document.readyState") { complete, _ in
                    guard complete != nil else { return }
                    webView.evaluateJavaScript("document.body.scrollHeight") { height, _ in
                        guard let height = height as? CGFloat else { return }
                        self.contentHeight = height
                    }
                }
            }
        }
    }
}

extension URLSession {
    var authenticationCookie: [HTTPCookie]? {
        let cookies = HTTPCookieStorage.shared.cookies
        return cookies
    }
}

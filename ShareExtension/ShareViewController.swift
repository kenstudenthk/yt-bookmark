import UIKit
import SwiftUI

/// NSExtensionPrincipalClass for the YT Bookmark Share Extension.
/// Extracts the shared URL, then presents a SwiftUI confirmation sheet.
final class ShareViewController: UIViewController {

    private let viewModel = ShareViewModel()
    private var hostingController: UIHostingController<ShareView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        embedShareView()
        loadSharedURL()
    }

    // MARK: - Setup

    private func embedShareView() {
        guard let context = extensionContext else { return }

        let shareView = ShareView(viewModel: viewModel, context: context)
        let hosting = UIHostingController(rootView: shareView)
        hostingController = hosting

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }

    private func loadSharedURL() {
        guard let context = extensionContext else { return }
        Task {
            await viewModel.loadURL(from: context)
        }
    }
}

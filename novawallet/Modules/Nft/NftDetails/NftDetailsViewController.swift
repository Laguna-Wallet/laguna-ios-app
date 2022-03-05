import UIKit
import SoraFoundation

final class NftDetailsViewController: UIViewController, ViewHolder {
    typealias RootViewType = NftDetailsViewLayout

    let presenter: NftDetailsPresenterProtocol

    init(presenter: NftDetailsPresenterProtocol, localizationManager: LocalizationManagerProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NftDetailsViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupHandlers()
        setupLocalization()

        presenter.setup()
    }

    private func setupLocalization() {
        rootView.locale = selectedLocale
    }

    private func setupHandlers() {
        rootView.ownerCell.addTarget(self, action: #selector(actionOwner), for: .touchUpInside)
    }

    private func createStackViewModel(
        from displayAddress: DisplayAddressViewModel
    ) -> (StackCellViewModel, NSLineBreakMode) {
        if let name = displayAddress.name {
            let viewModel = StackCellViewModel(
                details: name,
                imageViewModel: displayAddress.imageViewModel
            )

            return (viewModel, .byTruncatingTail)
        } else {
            let viewModel = StackCellViewModel(
                details: displayAddress.address,
                imageViewModel: displayAddress.imageViewModel
            )

            return (viewModel, .byTruncatingMiddle)
        }
    }

    @objc func actionOwner() {
        presenter.selectOwner()
    }

    @objc func actionIssuer() {
        presenter.selectIssuer()
    }
}

extension NftDetailsViewController: NftDetailsViewProtocol {
    func didReceive(name: String?) {
        rootView.titleLabel.text = name
    }

    func didReceive(label: String?) {
        rootView.subtitleView.isHidden = label == nil
        rootView.subtitleView.titleLabel.text = label
    }

    func didReceive(description: String?) {
        rootView.detailsLabel.text = description
    }

    func didReceive(media: NftMediaViewModelProtocol?) {
        if let media = media {
            rootView.mediaView.bind(
                viewModel: media,
                targetSize: NftDetailsViewLayout.mediaSize,
                cornerRadius: 0.0
            )
        } else {
            rootView.mediaView.bindPlaceholder()
        }
    }

    func didReceive(price: BalanceViewModelProtocol?) {
        if let price = price {
            let priceView = rootView.setupPriceViewIfNeeded()
            priceView.bind(viewModel: price)
        } else {
            rootView.removePriceViewIfNeeded()
        }
    }

    func didReceive(collectionViewModel: StackCellViewModel?) {
        guard let collectionViewModel = collectionViewModel else {
            rootView.removeCollectionViewIfNeeded()
            return
        }

        let collectionView = rootView.setupCollectionViewIfNeeded()
        collectionView.bind(viewModel: collectionViewModel)
    }

    func didReceive(ownerViewModel: DisplayAddressViewModel) {
        let (viewModel, lineBreakMode) = createStackViewModel(from: ownerViewModel)

        rootView.ownerCell.bind(viewModel: viewModel)
        rootView.ownerCell.detailsLabel.lineBreakMode = lineBreakMode
    }

    func didReceive(issuerViewModel: DisplayAddressViewModel?) {
        guard let issuerViewModel = issuerViewModel else {
            rootView.removeIssueViewIfNeeded()
            return
        }

        let shouldSetupHandler = rootView.issuerCell == nil
        let issuerView = rootView.setupIssuerViewIfNeeded()

        let (viewModel, lineBreakMode) = createStackViewModel(from: issuerViewModel)

        issuerView.bind(viewModel: viewModel)
        issuerView.detailsLabel.lineBreakMode = lineBreakMode

        if shouldSetupHandler {
            issuerView.addTarget(self, action: #selector(actionIssuer), for: .touchUpInside)
        }
    }

    func didReceive(networkViewModel: NetworkViewModel) {
        rootView.networkCell.bind(viewModel: networkViewModel)
    }
}

extension NftDetailsViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
        }
    }
}

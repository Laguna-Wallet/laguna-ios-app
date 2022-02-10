import Foundation
import SoraKeystore
import SoraFoundation

struct DAppOperationConfirmViewFactory {
    static func createView(
        for request: DAppOperationRequest,
        type: DAppSigningType,
        delegate: DAppOperationConfirmDelegate
    ) -> DAppOperationConfirmViewProtocol? {
        let maybeInteractor: (DAppOperationBaseInteractor & DAppOperationConfirmInteractorInputProtocol)?
        let maybeAssetInfo: AssetBalanceDisplayInfo?

        switch type {
        case let .extrinsic(chain):
            maybeAssetInfo = chain.utilityAssets().first?.displayInfo(with: chain.icon)
            maybeInteractor = createExtrinsicInteractor(for: request, chain: chain)
        case let .bytes(chain):
            maybeAssetInfo = chain.utilityAssets().first?.displayInfo(with: chain.icon)
            maybeInteractor = createSignBytesInteractor(for: request, chain: chain)
        case let .ethereumTransaction(chain):
            maybeAssetInfo = chain.assetDisplayInfo
            maybeInteractor = nil
        }

        guard let interactor = maybeInteractor, let assetInfo = maybeAssetInfo else {
            return nil
        }

        let wireframe = DAppOperationConfirmWireframe()

        let balanceViewModelFactory = BalanceViewModelFactory(targetAssetInfo: assetInfo)

        let presenter = DAppOperationConfirmPresenter(
            interactor: interactor,
            wireframe: wireframe,
            delegate: delegate,
            viewModelFactory: DAppOperationConfirmViewModelFactory(),
            balanceViewModelFactory: balanceViewModelFactory,
            localizationManager: LocalizationManager.shared,
            logger: Logger.shared
        )

        let view = DAppOperationConfirmViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }

    private static func createExtrinsicInteractor(
        for request: DAppOperationRequest,
        chain: ChainModel
    ) -> DAppOperationConfirmInteractor? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry

        guard
            let connection = chainRegistry.getConnection(for: chain.chainId),
            let runtimeProvider = chainRegistry.getRuntimeProvider(for: chain.chainId) else {
            return nil
        }

        return DAppOperationConfirmInteractor(
            request: request,
            chain: chain,
            runtimeProvider: runtimeProvider,
            connection: connection,
            signingWrapperFactory: SigningWrapperFactory(keystore: Keychain()),
            priceProviderFactory: PriceProviderFactory.shared,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )
    }

    private static func createSignBytesInteractor(
        for request: DAppOperationRequest,
        chain: ChainModel
    ) -> DAppSignBytesConfirmInteractor {
        DAppSignBytesConfirmInteractor(
            request: request,
            chain: chain,
            signingWrapperFactory: SigningWrapperFactory(keystore: Keychain())
        )
    }
}

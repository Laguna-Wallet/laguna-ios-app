import Foundation

struct DAppSearchViewFactory {
    static func createView(with initialQuery: String?, delegate: DAppSearchDelegate) -> DAppSearchViewProtocol? {
        let interactor = DAppSearchInteractor()
        let wireframe = DAppSearchWireframe()

        let presenter = DAppSearchPresenter(
            interactor: interactor,
            wireframe: wireframe,
            initialQuery: initialQuery,
            delegate: delegate
        )

        let view = DAppSearchViewController(presenter: presenter)

        presenter.view = view
        interactor.presenter = presenter

        return view
    }
}

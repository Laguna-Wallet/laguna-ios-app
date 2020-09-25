import Foundation
import CommonWallet
import SoraKeystore
import RobinHood
import IrohaCrypto
import SoraFoundation

enum WalletContextFactoryError: Error {
    case missingNode
    case missingAccount
}

protocol WalletContextFactoryProtocol {
    func createContext() throws -> CommonWalletContextProtocol
}

final class WalletContextFactory {
    let keychain: KeystoreProtocol
    let settings: SettingsManagerProtocol
    let applicationConfig: ApplicationConfigProtocol
    let logger: LoggerProtocol
    let primitiveFactory: WalletPrimitiveFactoryProtocol

    init(keychain: KeystoreProtocol = Keychain(),
         settings: SettingsManagerProtocol = SettingsManager.shared,
         applicationConfig: ApplicationConfigProtocol = ApplicationConfig.shared,
         logger: LoggerProtocol = Logger.shared) {
        self.keychain = keychain
        self.settings = settings
        self.applicationConfig = applicationConfig
        self.logger = logger

        primitiveFactory = WalletPrimitiveFactory(keystore: keychain,
                                                  settings: settings)
    }

    private func subscribeContextToLanguageSwitch(_ context: CommonWalletContextProtocol,
                                                  localizationManager: LocalizationManagerProtocol,
                                                  logger: LoggerProtocol) {
        localizationManager.addObserver(with: context) { [weak context] (_, newLocalization) in
            if let newLanguage = WalletLanguage(rawValue: newLocalization) {
                do {
                    try context?.prepareLanguageSwitchCommand(with: newLanguage).execute()
                } catch {
                    logger.error("Error received when tried to change wallet language")
                }
            } else {
                logger.error("New selected language \(newLocalization) error is unsupported")
            }
        }
    }
}

extension WalletContextFactory: WalletContextFactoryProtocol {
    func createContext() throws -> CommonWalletContextProtocol {
        guard let selectedAccount = SettingsManager.shared.selectedAccount else {
            throw WalletContextFactoryError.missingAccount
        }

        let accountSettings = try primitiveFactory.createAccountSettings()

        logger.debug("Loading wallet account: \(selectedAccount.address)")

        let nodeUrl = SettingsManager.shared.selectedConnection.url
        let networkType = SettingsManager.shared.selectedConnection.type

        let accountSigner = SigningWrapper(keystore: Keychain(), settings: SettingsManager.shared)
        let dummySigner = try DummySigner(cryptoType: selectedAccount.cryptoType)

        let networkFactory = WalletNetworkOperationFactory(url: nodeUrl,
                                                           accountSettings: accountSettings,
                                                           accountSigner: accountSigner,
                                                           dummySigner: dummySigner,
                                                           logger: logger)

        let builder = CommonWalletBuilder.builder(with: accountSettings, networkOperationFactory: networkFactory)

        let localizationManager = LocalizationManager.shared

        WalletCommonConfigurator(localizationManager: localizationManager).configure(builder: builder)
        WalletCommonStyleConfigurator().configure(builder: builder.styleBuilder)

        let accountListConfigurator = WalletAccountListConfigurator(logger: logger)
        accountListConfigurator.configure(builder: builder.accountListModuleBuilder)

        TransactionHistoryConfigurator().configure(builder: builder.historyModuleBuilder)

        let contactsConfigurator = ContactsConfigurator(networkType: networkType)
        contactsConfigurator.configure(builder: builder.contactsModuleBuilder)

        let context = try builder.build()

        subscribeContextToLanguageSwitch(context,
                                         localizationManager: localizationManager,
                                         logger: logger)

        accountListConfigurator.context = context
        contactsConfigurator.commandFactory = context

        return context
    }
}

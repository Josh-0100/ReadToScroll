import ManagedSettings
import ManagedSettingsUI
import UIKit
import RewardCore

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let copy = ShieldCopy.make(for: SharedStore().loadState())
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            icon: UIImage(systemName: "book.fill"),
            title: .init(text: copy.title, color: .white),
            subtitle: .init(text: copy.subtitle, color: .lightGray),
            primaryButtonLabel: .init(text: "Close", color: .black),
            primaryButtonBackgroundColor: .white
        )
    }
}

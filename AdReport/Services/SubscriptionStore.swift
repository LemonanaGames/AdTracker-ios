import Foundation
#if canImport(RevenueCat)
import RevenueCat
#endif

/// Fill from your RevenueCat dashboard. Empty key → demo mode (paywall unlocks locally).
enum Secrets {
    static let revenueCatAPIKey = ""          // "appl_xxxxxxxxxxxx"
    static let proEntitlementID = "pro"
}

struct PlanOption: Identifiable, Hashable {
    let id: String
    let name: String
    let price: String
    let sub: String
}

/// Wraps RevenueCat for the `Reporting Pro` entitlement. Compiles without the package
/// (demo mode) thanks to the `canImport` guard.
@MainActor @Observable
final class SubscriptionStore {
    var isPro = false
    var plans: [PlanOption] = []

    var isConfigured: Bool {
        #if canImport(RevenueCat)
        return !Secrets.revenueCatAPIKey.isEmpty
        #else
        return false
        #endif
    }

    #if canImport(RevenueCat)
    private var packagesByID: [String: Package] = [:]
    #endif

    func configure() {
        #if canImport(RevenueCat)
        guard isConfigured else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Secrets.revenueCatAPIKey)
        #endif
    }

    func refresh() async {
        #if canImport(RevenueCat)
        guard isConfigured else { return }
        if let info = try? await Purchases.shared.customerInfo() {
            isPro = info.entitlements[Secrets.proEntitlementID]?.isActive == true
        }
        if let offering = try? await Purchases.shared.offerings().current {
            packagesByID = Dictionary(uniqueKeysWithValues: offering.availablePackages.map { ($0.identifier, $0) })
            plans = offering.availablePackages.map {
                PlanOption(id: $0.identifier,
                           name: $0.storeProduct.localizedTitle,
                           price: $0.storeProduct.localizedPriceString,
                           sub: $0.packageType == .lifetime ? "One-time · best value" : "")
            }
        }
        #endif
    }

    @discardableResult
    func purchase(planID: String) async -> Bool {
        #if canImport(RevenueCat)
        guard let package = packagesByID[planID] else { return false }
        if let result = try? await Purchases.shared.purchase(package: package) {
            isPro = result.customerInfo.entitlements[Secrets.proEntitlementID]?.isActive == true
            return isPro
        }
        return false
        #else
        return false
        #endif
    }

    @discardableResult
    func restore() async -> Bool {
        #if canImport(RevenueCat)
        if let info = try? await Purchases.shared.restorePurchases() {
            isPro = info.entitlements[Secrets.proEntitlementID]?.isActive == true
            return isPro
        }
        return false
        #else
        return false
        #endif
    }
}

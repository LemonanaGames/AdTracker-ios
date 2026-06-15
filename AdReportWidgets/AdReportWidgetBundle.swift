import WidgetKit
import SwiftUI

@main
struct AdReportWidgetBundle: WidgetBundle {
    var body: some Widget {
        RevenueWidget()
        TopAppsWidget()
        RevenueControl()
        #if canImport(ActivityKit)
        RevenueLiveActivity()
        #endif
    }
}

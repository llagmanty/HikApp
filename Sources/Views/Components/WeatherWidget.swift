import SwiftUI

struct WeatherWidget: View {
    let temperature: Measurement<UnitTemperature>?
    let symbolName: String
    let isFetching: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.callout)
            if let temp = temperature {
                Text(temp.localizedString)
                    .font(.system(.callout, design: .rounded).bold())
                    .foregroundStyle(.primary)
            } else if isFetching {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

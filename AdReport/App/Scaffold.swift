import SwiftUI

/// Tab-root chrome: a fixed large title + a scrolling body (port of the design's `Scaffold` tab mode).
struct TabScaffold<Trailing: View, Content: View>: View {
    @Environment(\.theme) private var t
    var title: String?
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() },
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title {
                HStack(alignment: .bottom) {
                    Text(title)
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(t.text)
                    Spacer()
                    trailing
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .padding(.top, 4)
            }
            ScrollView { content.padding(.bottom, 28) }
        }
        .background(t.bg)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Pushed-screen chrome: a back pill + optional trailing + optional big title (port of `Scaffold` push mode).
struct PushScaffold<Trailing: View, Content: View>: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var title: String?
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() },
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: Sym.chevronL)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(t.accent)
                        .frame(width: 38, height: 38)
                        .background(t.card, in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
                trailing
            }
            .padding(.horizontal, 12)
            .frame(height: 44)

            if let title {
                Text(title)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(t.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4).padding(.bottom, 12)
            }
            ScrollView { content.padding(.bottom, 24) }
        }
        .background(t.bg)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Sheet chrome: grab handle, title + close button, scrolling body (port of `Scaffold` sheet mode).
struct SheetScaffold<Content: View>: View {
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.system(size: 20, weight: .bold)).foregroundStyle(t.text)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: Sym.xmark)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(t.sec)
                        .frame(width: 30, height: 30)
                        .background(t.card2, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 8)
            ScrollView { content }
        }
        .background(t.bg)
        .presentationDragIndicator(.visible)
    }
}

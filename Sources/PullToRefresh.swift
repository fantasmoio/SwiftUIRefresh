import SwiftUI
import Introspect

private struct PullToRefresh: UIViewRepresentable {
    
    @Binding var isShowing: Bool
    let onRefresh: () -> Void
    
    public init(isShowing: Binding<Bool>, onRefresh: @escaping () -> Void) {
        _isShowing = isShowing
        self.onRefresh = onRefresh
    }
    
    public class Coordinator {
        let onRefresh: () -> Void
        let isShowing: Binding<Bool>
        
        init(onRefresh: @escaping () -> Void, isShowing: Binding<Bool>) {
            self.onRefresh = onRefresh
            self.isShowing = isShowing
        }
        
        @objc
        func onValueChanged() {
            isShowing.wrappedValue = true
            onRefresh()
        }
    }
    
    public func makeUIView(context: UIViewRepresentableContext<PullToRefresh>) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }

    public func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PullToRefresh>) {
        DispatchQueue.main.async { [isShowing] in
            guard let scrollView: UIScrollView = TargetViewSelector.ancestorOrSiblingContaining(from: uiView) else {
                return
            }

            if scrollView.refreshControl == nil {
                let refreshControl = UIRefreshControl()
                refreshControl.addTarget(context.coordinator,
                                         action: #selector(Coordinator.onValueChanged),
                                         for: .valueChanged)
                scrollView.refreshControl = refreshControl
            }

            if let refreshControl = scrollView.refreshControl {
                if isShowing {
                    if !refreshControl.isRefreshing {
                        let y = scrollView.contentOffset.y - refreshControl.bounds.size.height
                        scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
                        refreshControl.beginRefreshing()
                    }
                } else {
                    if refreshControl.isRefreshing {
                        refreshControl.endRefreshing()
                    }
                }
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(onRefresh: onRefresh, isShowing: $isShowing)
    }
}

extension View {
    public func pullToRefresh(isShowing: Binding<Bool>, onRefresh: @escaping () -> Void) -> some View {
        inject(PullToRefresh(isShowing: isShowing, onRefresh: onRefresh))
    }
}

import Combine
import UIKit
@_spi(ViewEnvironmentWiring) import ViewEnvironmentUI

/// A concrete implementation of `ModalListObserver` which observes `ModalListProvider`s and presents/dismisses
/// modals and toasts defined by that observable as it changes over time as long as the associated observation lifetime
/// is retained.
///
final class TrampolineModalListObserver: ModalListObserver {

    weak var owner: UIViewController?
    var environmentUpdateObservationLifetime: ViewEnvironmentUpdateObservationLifetime?
    private var modalListObservations: [ModalListObservation] = []

    init(owner: UIViewController) {
        self.owner = owner

        // Listen for environment updates
        environmentUpdateObservationLifetime = owner.addEnvironmentNeedsUpdateObserver { [weak self] environment in
            guard let self else { return }

            for provider in modalListObservations.map(\.provider) {
                provider.update(environment: environment)
            }
        }
    }

    func setModalHostNeedsUpdate(requiringModalHost modalHostRequired: Bool) {
        guard let owner else {
            return
        }

        guard let host = owner.modalHost else {
            if modalHostRequired {
                ModalHostAsserts.noFoundModalHostFatalError(in: owner)
            } else {
                return
            }
        }

        host.setNeedsModalUpdate()
    }

    func observe(_ provider: ModalListProvider) -> ModalListObservationLifetime {
        guard let owner else {
            fatalError(
                """
                No owning view controller was found when attempting to observe ModalListProvider. \
                This is not expected to be nil, and indicates an error in the Modals framework.
                """
            )
        }

        if let currentObservation = modalListObservations.first(where: { $0.provider === provider }) {
            guard let lifetime = currentObservation.lifetime else {
                fatalError("ModalListProvider lifetime was nil when attempting to return an existing observation.")
            }

            return lifetime
        }

        // Ensure an up-to-date environment at the start of observation.
        provider.update(environment: owner.environment)

        let cancellable = provider.modalListDidChange.sink { [weak self] _ in
            guard let self,
                  modalListObservations.isEmpty == false
            else { return }

            setModalHostNeedsUpdate(requiringModalHost: false)
        }

        let lifetime = ObservationLifetimeToken(onStopObserving: { [weak self] in
            guard let self else { return }

            guard let index = modalListObservations.firstIndex(where: { $0.provider === provider }) else {
                return
            }

            let observation = modalListObservations.remove(at: index)
            observation.cancellable.cancel()
        })

        modalListObservations.append(.init(
            provider: provider,
            cancellable: cancellable,
            lifetime: lifetime
        ))

        setModalHostNeedsUpdate(requiringModalHost: false)

        return lifetime
    }

    func aggregateModalList() -> ModalList {
        modalListObservations
            .map { $0.provider.aggregateModalList() }
            .reduce(ModalList(), +)
    }
}


extension TrampolineModalListObserver {

    fileprivate final class ObservationLifetimeToken: ModalListObservationLifetime {
        private var onStopObserving: (() -> Void)?

        init(onStopObserving: @escaping () -> Void) {
            self.onStopObserving = onStopObserving
        }

        deinit {
            onStopObserving?()
        }

        func stopObserving() {
            onStopObserving?()
            onStopObserving = nil
        }
    }

    fileprivate struct ModalListObservation {
        var provider: ModalListProvider
        var cancellable: AnyCancellable
        weak var lifetime: ModalListObservationLifetime?
    }
}

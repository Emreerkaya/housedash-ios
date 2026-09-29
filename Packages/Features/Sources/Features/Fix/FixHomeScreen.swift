import SwiftUI
import DesignSystem

public struct FixHomeScreen: View {
    @State private var model: IntakeFlowModel

    public init(problemCatalogue: ProblemCatalogue, camera: PhotoCapture) {
        _model = State(initialValue: IntakeFlowModel(catalogue: problemCatalogue, camera: camera))
    }

    public var body: some View {
        NavigationStack(path: $model.path) {
            B01FixScreen(model: model)
                .hdFlowScreen()
                .navigationDestination(for: IntakeRoute.self) { route in
                    destination(for: route)
                        .hdFlowScreen()
                }
        }
    }

    @ViewBuilder
    private func destination(for route: IntakeRoute) -> some View {
        switch route {
        case .pickProblem:
            B02PickProblemScreen(model: model)
        case .describeIt(let symptom):
            B03DescribeItScreen(model: model, symptom: symptom)
        case .somethingElse:
            B04SomethingElseScreen(model: model)
        case .photograph:
            B06PhotographItScreen(model: model)
        }
    }
}

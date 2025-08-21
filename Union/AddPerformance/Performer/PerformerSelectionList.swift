import SwiftUI

struct PerformerSelectionList: View {
    @ObservedObject var festivalViewModel: FestivalViewModel
    @Binding var performerInputs: Set<PerformerInput>
    
    var body: some View {
        List {
            ForEach(Array(festivalViewModel.knownPerformers), id: \.self) { performerName in
                Toggle(isOn: binding(for: performerName)) {
                    Text(performerName)
                }
            }
        }
    }
    
    private func binding(for performerName: String) -> Binding<Bool> {
        let performer = PerformerInput(name: performerName)
        return Binding<Bool>(
            get: { performerInputs.contains(performer) },
            set: { isSelected in
                if isSelected {
                    performerInputs.insert(performer)
                } else {
                    performerInputs.remove(performer)
                }
            }
        )
    }
}

import SwiftUI

struct InfoView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Image("UnionLogoCrop")
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .padding(.vertical, 20)
            }
            .background(.black)
            List {
                VStack {
                    Section {
                        infoBlock(
                            title: "Location",
                            lines: ["593 Somerville Ave, Somerville, MA"]
                        )
                    }
                    
                    Section {
                        Divider()
                        infoBlock(
                            title: "Contact",
                            lines: ["info@unioncomedy.com"]
                        )
                    }
                    
                    Section {
                        Divider()
                        infoBlock(
                            title: "Hours",
                            lines: [
                                "Friday–Saturday: 7–10pm",
                                "Sunday: 5–8pm"
                            ]
                        )
                    }
                    
                    Section {
                        Divider()
                        infoBlock(
                            title: "Festival Location",
                            lines: ["255 Elm St, Somerville, MA 02144"]
                        )
                    }
                }
            }
        }
        .navigationTitle("About the Theatre")
    }
    
    @ViewBuilder
    private func infoBlock(title: String, lines: [String]) -> some View {
        VStack(spacing: 8) {
            Text("\(title):")
                .bold()
                .padding(.bottom, 8)
            
            ForEach(lines, id: \.self) {
                Text($0)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.vertical, 4)
    }
}

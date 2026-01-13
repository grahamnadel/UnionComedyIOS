import SwiftUI

struct TeamListPerformanceRow: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    let performance: Performance
    
    var body: some View {
        HStack(alignment: .center) {
            // Left Side: Date/Time info
            VStack(alignment: .leading, spacing: 4) {
                if let showType = ShowType.dateToShow(date: performance.showTime)?.displayName {
                    Text(showType.uppercased())
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.purple) // Accent color to make it pop
                        .kerning(1.2)
                }
                
                Text(performance.showTime, style: .date)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Right Side: Time Badge
            Text(performance.showTime, style: .time)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
        // If you ever use this outside of the DetailView,
        // this padding makes it look like a distinct card.
        .padding(.vertical, 4)
    }
}

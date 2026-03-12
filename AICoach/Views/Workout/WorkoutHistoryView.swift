import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {

    @Query(
        filter: #Predicate<TrainingSession> { $0.completed == true },
        sort: \TrainingSession.date,
        order: .reverse
    ) private var sessions: [TrainingSession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "Sin historial",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Tus sesiones completadas aparecerán aquí.")
                )
            } else {
                List {
                    ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { month in
                        Section(month.formatted(.dateTime.month(.wide).year())) {
                            ForEach(groupedSessions[month] ?? []) { session in
                                NavigationLink {
                                    WorkoutDetailView(session: session)
                                } label: {
                                    SessionCard(session: session)
                                        .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.large)
    }

    private var groupedSessions: [Date: [TrainingSession]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: session.date)) ?? session.date
        }
    }
}

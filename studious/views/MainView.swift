import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            TaskListView()

        }
        .frame(width: 375, height: 550)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

// Copyright (c) 2021-2025 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import EventKit
import SwiftUI

import Interact

struct ContentView: View {

    @ObservedObject var applicationModel: ApplicationModel
    @StateObject var windowModel: WindowModel

    @Environment(\.openURL) var openURL

    init(applicationModel: ApplicationModel) {
        self.applicationModel = applicationModel
        _windowModel = StateObject(wrappedValue: WindowModel(applicationModel: applicationModel))
    }

    var body: some View {
        NavigationSplitView {
            CalendarList(applicationModel: applicationModel, selections: $windowModel.selections)
                .frame(minWidth: 200)
        } detail: {
            HStack {
                if windowModel.loading {
                    PlaceholderView {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                } else if !windowModel.summaries.isEmpty {
                    YearView(summaries: windowModel.summaries)
                } else {
                    switch applicationModel.state {
                    case .unknown:
                        ProgressView()
                            .progressViewStyle(.circular)
                    case .authorized:
                        ContentUnavailableView {
                            Label("No Calendars Selected", systemImage: "calendar")
                        } description: {
                            Text("Select one or more calendars from the sidebar.")
                        }
                    case .unauthorized:
                        ContentUnavailableView {
                            Label("Limited Calendar Access", systemImage: "calendar")
                        } description: {
                            Text("Overview needs full access to your calendar to be able to display and summarize your events.",
                                 comment: "Calendar privacy usage description shown when the user has denied acccess.")
                            Button {
                                openURL(.settingsPrivacyCalendars)
                            } label: {
                                Text("Open Privacy Settings", comment: "Title of the button that opens System Settings.")
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 500, minHeight: 400)
            .navigationTitle(Text("Overview", comment: "Main window title."))
            .navigationSubtitle(windowModel.title)
            .toolbar {
                ToolbarItem {
                    Picker(selection: $windowModel.year) {
                        ForEach(applicationModel.years) { year in
                            Text(String(year)).tag(year)
                        }
                    } label: {
                        Text("Year", comment: "Toolbar year picker label.")
                    }
                }
            }
        }
        .presents($applicationModel.error)
        .onAppear {
            windowModel.start()
        }
        .onDisappear {
            windowModel.stop()
        }
    }
}

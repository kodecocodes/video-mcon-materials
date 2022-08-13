/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
//: [Previous](@previous)
import SwiftUI
//: ## Part 2: async/await
//: ### URLSession
// DONE: async function to download and decode RW domains
func fetchDomains() async throws -> [Domain] {
  let url = URL(string: "https://api.raywenderlich.com/api/domains")!
  let (data, _) = try await URLSession.shared.data(from: url)
  return try JSONDecoder().decode(Domains.self, from: data).data
}

// DONE: Task to run async function
Task {
  do {
    let domains = try await fetchDomains()
    for domain in domains {
      let attr = domain.attributes
      print("\(attr.name): \(attr.description) - \(attr.level)")
    }
  } catch {
    print(error)
  }
}
//: ### Asynchronous functions
// DONE: Create asynchronous func helloPauseGoodbye()
func helloPauseGoodbye() async throws {
  print("\nHello function")  // add " function"
  try await Task.sleep(until: .now + .seconds(1), clock: .continuous)
  print("Goodbye function")  // add " function"
}

// DONE: Call asynchronous func helloPauseGoodbye()
Task {
  try await helloPauseGoodbye()
}
//: ### Start here
// DONE: Call asynchronous Task.sleep
Task {
 print("\nHello")
 try await Task.sleep(until: .now + .seconds(1), clock: .continuous)
 print("Goodbye")
}

// sleep(_:) blocks thread
sleep(1)
print("wake up")

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

import SwiftUI
//: [Previous](@previous)

//: ### Part 3: Cancel a task
Task {
  print("\nDoing some work on an unnamed task")
  let sum = (1...100000).reduce(0, +)
  print("Unnamed task done: 1 + 2 + 3 ... 100000 = \(sum)")
}
print("Doing some work on the main queue")
print("Doing more work on the main queue")

// This task runs after previous task finishes
let task = Task {
  print("\nDoing some work on a named task")
  // DONE: Check for cancellation before doing work
//  try Task.checkCancellation()
  if Task.isCancelled {
    print("Task cancelled")
    throw CancellationError()
  }
  let sum = (1...100000).reduce(0, +)
  print("Named task done: 1 + 2 + 3 ... 100000 = \(sum)")
}
print("Doing yet more work on the main queue")

// DONE: Cancel task
task.cancel()
print("\nCanceled task")

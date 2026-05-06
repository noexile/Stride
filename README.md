# Sneaker Life Tracker

iOS app that tracks running-shoe mileage from HealthKit — so you know when to swap shoes before you get injured.

Apple doesn't surface this natively. This app fills the gap.

## What it does

- Track your shoes (name, purchase date, mileage threshold)
- Auto-import runs from HealthKit / Apple Watch
- Show cumulative mileage per shoe with exhaustion warnings

## Stack

- SwiftUI + SwiftData (on-device, iCloud-backed)
- HealthKit for workout data
- TestFlight → App Store Connect for distribution

## Dev setup

Requires Xcode on macOS. Open the `.xcodeproj`, select your target device, and run.

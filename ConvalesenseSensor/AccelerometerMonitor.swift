//
//  AccelerometerMonitor.swift
//  ConvalesenseSensor
//
//  Created by Spencer MacDonald on 26/01/2017.
//  Copyright © 2017 AskDAD Ltd. All rights reserved.
//

import Foundation
import CoreMotion

final class AccelerometerMonitor {
  private let motionManager: CMMotionManager
  let updateInterval: TimeInterval = 1
  
  /// Initalize a AccelerometerMonitor, returns nil if the device doesn't support motion
  init?() {
    let motionManager = CMMotionManager()
    
    guard motionManager.isAccelerometerAvailable else {
      return nil
    }
    
    self.motionManager = motionManager
  }
  
  /// Start Updating
  func startUpdates() {
    if motionManager.isAccelerometerAvailable {
      motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: { (startAccelerometerData, error) in
        if let startAccelerometerData = startAccelerometerData {
          print(startAccelerometerData)
        }
      })
      motionManager.accelerometerUpdateInterval = updateInterval
    }
  }
  
  /// Stop Updating
  func stopUpdates() {
    if motionManager.isAccelerometerAvailable {
      motionManager.stopAccelerometerUpdates()
    }
  }
}

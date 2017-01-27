//
//  PeripheralBroadcaster.swift
//  ConvalesenseSensor
//
//  Created by Spencer MacDonald on 26/01/2017.
//  Copyright © 2017 AskDAD Ltd. All rights reserved.
//

import Foundation
import CoreBluetooth

enum PeripheralService: String {
  case accelerometer = "BF5FE877-828E-46A7-962A-3B5C773D6860"
  case tap = "3D3FDA8C-09EC-44F6-97B5-CF3EDF90382B"
}

enum TapCharachteristic: String {
  case taps = "3D3FDA8B-09EC-44F6-97B5-CF3EDF90382B"
}

protocol PeripheralBroadcasterDelegate: class {
  func peripheralBroadcaster(_ peripheralBroadcaster: PeripheralBroadcaster, centralSubscriptionDidChange centralSubscription: PeripheralBroadcaster.CentralSubscription?)
}

class PeripheralBroadcaster: NSObject {
  struct CentralSubscription {
    let central: CBCentral
    let characteristic: CBCharacteristic
  }
  
  weak var delegate: PeripheralBroadcasterDelegate?
  
  var tapsCharacteristic: CBMutableCharacteristic!
  var tapService: CBMutableService!
  
  var peripheralManager: CBPeripheralManager!
  var centralSubscription: CentralSubscription!
  
  override init() {
    super.init()
    peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.global(qos: .utility))
    tapsCharacteristic = CBMutableCharacteristic(type: CBUUID(string: TapCharachteristic.taps.rawValue), properties: [.read, .write, .notify], value: nil, permissions: [.readable, .writeable])
    tapService = CBMutableService(type: CBUUID(string: PeripheralService.tap.rawValue), primary: true)
    tapService.characteristics = [tapsCharacteristic]
  }
  
  deinit {
    stopAdvertising()
  }
  
  func startAdvertising() {
    guard peripheralManager.isAdvertising == false else {
      return
    }
    
    peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey: "Convalesense", CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: PeripheralService.tap.rawValue)]])
  }
  
  func stopAdvertising() {
    guard peripheralManager.isAdvertising else {
      return
    }
    
    peripheralManager.stopAdvertising()
  }
}

extension PeripheralBroadcaster: CBPeripheralManagerDelegate {
  /*!
   *  @method peripheralManagerDidUpdateState:
   *
   *  @param peripheral   The peripheral manager whose state has changed.
   *
   *  @discussion         Invoked whenever the peripheral manager's state has been updated. Commands should only be issued when the state is
   *                      <code>CBPeripheralManagerStatePoweredOn</code>. A state below <code>CBPeripheralManagerStatePoweredOn</code>
   *                      implies that advertisement has paused and any connected centrals have been disconnected. If the state moves below
   *                      <code>CBPeripheralManagerStatePoweredOff</code>, advertisement is stopped and must be explicitly restarted, and the
   *                      local database is cleared and all services must be re-added.
   *
   *  @see                state
   *
   */
  @available(iOS 6.0, *)
  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    print(#function)
    
    switch peripheral.state {
    case .poweredOn:
      peripheralManager.add(tapService)
      startAdvertising()
    default:
      print("unhandled state")
    }
  }
  
  
  /*!
   *  @method peripheralManagerDidStartAdvertising:error:
   *
   *  @param peripheral   The peripheral manager providing this information.
   *  @param error        If an error occurred, the cause of the failure.
   *
   *  @discussion         This method returns the result of a @link startAdvertising: @/link call. If advertisement could
   *                      not be started, the cause will be detailed in the <i>error</i> parameter.
   *
   */
  public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    if let error = error {
      print("\(#function) \(error)")
    } else {
      print(#function)
    }
  }
  
  
  /*!
   *  @method peripheralManager:didAddService:error:
   *
   *  @param peripheral   The peripheral manager providing this information.
   *  @param service      The service that was added to the local database.
   *  @param error        If an error occurred, the cause of the failure.
   *
   *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
   *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
   *
   */
  public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    print("\(#function) \(service) \(error)")
  }
  
  
  /*!
   *  @method peripheralManager:central:didSubscribeToCharacteristic:
   *
   *  @param peripheral       The peripheral manager providing this update.
   *  @param central          The central that issued the command.
   *  @param characteristic   The characteristic on which notifications or indications were enabled.
   *
   *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
   *                          It should be used as a cue to start sending updates as the characteristic value changes.
   *
   */
  public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
    print(#function)
    
    guard centralSubscription == nil else {
      return
    }
    
    centralSubscription = CentralSubscription(central: central, characteristic: characteristic)
    delegate?.peripheralBroadcaster(self, centralSubscriptionDidChange: centralSubscription)
  }
  
  
  /*!
   *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
   *
   *  @param peripheral       The peripheral manager providing this update.
   *  @param central          The central that issued the command.
   *  @param characteristic   The characteristic on which notifications or indications were disabled.
   *
   *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
   *
   */
  public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
    print(#function)
    
    guard let centralSubscription = centralSubscription, centralSubscription.central == central, centralSubscription.characteristic == characteristic else {
      return
    }
    
    self.centralSubscription = nil
    delegate?.peripheralBroadcaster(self, centralSubscriptionDidChange: nil)
  }
  
  /*!
   *  @method peripheralManager:didReceiveReadRequest:
   *
   *  @param peripheral   The peripheral manager requesting this information.
   *  @param request      A <code>CBATTRequest</code> object.
   *
   *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
   *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
   *
   *  @see                CBATTRequest
   *
   */
  public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
    print(#function)
  }
  
  
  /*!
   *  @method peripheralManager:didReceiveWriteRequests:
   *
   *  @param peripheral   The peripheral manager requesting this information.
   *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
   *
   *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
   *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
   *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
   *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
   *
   *  @see                CBATTRequest
   *
   */
  public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    print(#function)
  }
  
  
  /*!
   *  @method peripheralManagerIsReadyToUpdateSubscribers:
   *
   *  @param peripheral   The peripheral manager providing this update.
   *
   *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
   *                      ready to send characteristic value updates.
   *
   */
  public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager){
    print(#function)
  }
}

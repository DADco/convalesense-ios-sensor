//
//  AdvertisingController.swift
//  ConvalesenseSensor
//
//  Created by Spencer MacDonald on 26/01/2017.
//  Copyright © 2017 AskDAD Ltd. All rights reserved.
//

import UIKit

class AdvertisingController: UIViewController {
  var peripheralBroadcaster: PeripheralBroadcaster!

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    peripheralBroadcaster = PeripheralBroadcaster()
    peripheralBroadcaster.delegate = self
    
    navigationItem.titleView = UIImageView(image:#imageLiteral(resourceName: "convalesense"))
    navigationItem.setHidesBackButton(true, animated: false)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    peripheralBroadcaster.startAdvertising()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "MakeItRain", let destination = segue.destination as? MakeItRainController {
      destination.peripheralBroadcaster = peripheralBroadcaster
    }
  }
}

extension AdvertisingController: PeripheralBroadcasterDelegate {
  func peripheralBroadcaster(_ peripheralBroadcaster: PeripheralBroadcaster, centralSubscriptionDidChange centralSubscription: PeripheralBroadcaster.CentralSubscription?) {
    DispatchQueue.main.async {
      if let _ = centralSubscription {
        self.performSegue(withIdentifier: "MakeItRain", sender: nil)
      } else {
        _ = self.navigationController?.popToViewController(self, animated: true)
      }
    }
  }
}

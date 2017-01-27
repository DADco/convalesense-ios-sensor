//
//  MakeInRainController.swift
//  ConvalesenseSensor
//
//  Created by Spencer MacDonald on 26/01/2017.
//  Copyright © 2017 AskDAD Ltd. All rights reserved.
//

import UIKit
import CoreBluetooth

class MakeItRainController: UIViewController {
  @IBOutlet var imageView: UIImageView!
  
  var peripheralBroadcaster: PeripheralBroadcaster!
  
  var tapGestureRecognizer: UITapGestureRecognizer!
  
  var tapCount: Int = 0
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    navigationItem.titleView = UIImageView(image:#imageLiteral(resourceName: "convalesense"))
    navigationItem.setHidesBackButton(true, animated: false)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = UIImage.animatedImage(with: [#imageLiteral(resourceName: "Water Intro 1"),#imageLiteral(resourceName: "Water Intro 2"),#imageLiteral(resourceName: "Water Intro 3"),#imageLiteral(resourceName: "Water Intro 4")], duration: 1)
  
    imageView.isUserInteractionEnabled = false
    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:)))
    view.addGestureRecognizer(tapGestureRecognizer)
  }
  
  func tapGestureRecognized(_ tapGestureRecognizer: UITapGestureRecognizer) {
    tapCount += 1
    
    DispatchQueue.global(qos: .utility).async {
      let data = try! JSONSerialization.data(withJSONObject: ["tapCount" : self.tapCount], options: [])
      self.peripheralBroadcaster.tapsCharacteristic.value = data
      let sent = self.peripheralBroadcaster.peripheralManager.updateValue(data, for: self.peripheralBroadcaster.tapsCharacteristic, onSubscribedCentrals: nil)
      
      if sent {
        print("sent \(data)")
      } else {
        print("failed to send \(data)")
      }
    }
  }
}

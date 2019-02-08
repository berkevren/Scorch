/*
* Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

import UIKit
import AWSIoT
import AVFoundation

class SubscribeViewController: UIViewController {

    @IBOutlet weak var subscribeSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        subscribeSlider.isEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        let iotDataManager = AWSIoTDataManager(forKey: ASWIoTDataManager)
        let tabBarViewController = tabBarController as! IoTSampleTabBarController

        iotDataManager.subscribe(toTopic: tabBarViewController.topic, qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: {
            (payload) ->Void in
            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!
            
            print("received: \(stringValue)")
            DispatchQueue.main.async {
                self.subscribeSlider.value = stringValue.floatValue
            }
            
            if ( (Double(String(stringValue)) ?? 0) > 30.0) {
                let alert = UIAlertController(title: "Alert", message: "Slider has gone higher than 30. Please reduce.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } )
        
        let flashlightTopic = "torch"
        iotDataManager.subscribe(toTopic: flashlightTopic, qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: {
            (torchtoggle) ->Void in
            let stringValue = NSString(data: torchtoggle, encoding: String.Encoding.utf8.rawValue)!
            
            print("received: \(stringValue)")
            if(stringValue.floatValue == 0) {
                print("should toggle on")
                self.toggleTorch(on: true)
            } else {
                print("should toggle off")
                self.toggleTorch(on: false)
            }
        } )
        
        iotDataManager.publishString("{}", onTopic: "$aws/things/berksiphone/shadow/get", qoS: .messageDeliveryAttemptedAtMostOnce)
        iotDataManager.subscribe(toTopic: "$aws/things/berksiphone/shadow/get/accepted", qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: {
            (payload) ->Void in
            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!
            
            //print("received: \(stringValue)")
            
            do {
                let json = try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any]
                let jsonState = json?["state"] as? NSDictionary
                let jsonStateDesired = jsonState?["desired"] as? NSDictionary
                print(jsonStateDesired)
            } catch {
                print(error.localizedDescription)
            }
            })
    }

    override func viewWillDisappear(_ animated: Bool) {
        let iotDataManager = AWSIoTDataManager(forKey: ASWIoTDataManager)
        let tabBarViewController = tabBarController as! IoTSampleTabBarController
        iotDataManager.unsubscribeTopic(tabBarViewController.topic)
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)
            else {return}
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
}


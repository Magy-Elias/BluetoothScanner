//
//  ItemsViewController.swift
//  BluetoothScanner
//
//  Created by Beat Besmer on 27.06.17.
//  Copyright © 2017 Besmer Labs. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth


class ItemsViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    var manager: CBCentralManager!
    
    
    /**********************************************************/
    var peripheral: CBPeripheral!
    var characteristics: [CBCharacteristic]?
    /**********************************************************/
    
    
    let scanningDelay = 1.0
    var items = [String: [String: Any]]()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.keys.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        
        // Configure the cell...
        if let item = itemForIndexPath(indexPath){
            cell.textLabel?.text = item["name"] as? String
            
            if let rssi = item["rssi"] as? Int {
                cell.detailTextLabel?.text = "\(rssi.description) dBm"
            } else {
                cell.detailTextLabel?.text = ""
            }
        }
        
        return cell
    }
    
    
    /**********************************************************/
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let index = indexPath.row
//        print(index)
//        print(String(describing: itemForIndexPath(indexPath)!["name"]))
        
//        let action = UIAlertController(title: "Device Choosen", message: "Device \(indexPath.row)", preferredStyle: .alert)
        
        let action = UIAlertController(title: "Device Choosen", message: String(describing: itemForIndexPath(indexPath)!["name"]), preferredStyle: .alert)
        let twitterAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        action.addAction(twitterAction)
        action.addAction(cancelAction)
        self.present(action, animated: true, completion: nil)
    }
    /**********************************************************/
    
    
    func itemForIndexPath(_ indexPath: IndexPath) -> [String: Any]?{
        
        if indexPath.row > items.keys.count{
            return nil
        }
        
        return Array(items.values)[indexPath.row]
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        if central.state == .poweredOn{
            manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        
        didReadPeripheral(peripheral, rssi: RSSI)
        
        
        /**********************************************************/
        print("PERIPHERAL NAME: \(String(describing: peripheral.name))")
        print("PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
        
        if peripheral.identifier.uuidString == "2D5AEE6E-2677-DD6E-C231-9C704063E36F" {
            self.manager.stopScan()

            self.peripheral = peripheral
            self.peripheral!.delegate = self

            manager.connect(peripheral, options: nil)

//            print("discovered \(String(describing: peripheral.name))")
            print("discovered \(String(describing: peripheral))")
        }
        /**********************************************************/
        
        
    }
    
    
    /**********************************************************/
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service.uuid)")
                // If we found either the temperature or the humidity service, discover the characteristics for those services.
//                if (service.UUID == CBUUID(string: Device.TemperatureServiceUUID)) ||
//                    (service.UUID == CBUUID(string: Device.HumidityServiceUUID)) {
                peripheral.discoverCharacteristics(nil, for: service)
//                }
            }
        }
    }
    
    
    /*
     Invoked when you retrieve a specified characteristic’s value,
     or when the peripheral device notifies your app that the characteristic’s value has changed.
     
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for
     which notifications and indications are enabled has changed.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
//    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        if error != nil {
//            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
//            return
//        }
//
//        print("get greater data")
//        // extract the data from the characteristic's value property and display the value based on the characteristic type
//        if let dataBytes = characteristic.value {
//            print("get data")
////            if characteristic.UUID == CBUUID(_:"FFF4") {
//////                displayTemperature(dataBytes)
////                print("get data")
////            }
//        }
//    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error:Error?)
    {
        print("Found \(service.characteristics!.count) characteristics!: \(String(describing: service.characteristics))")
        self.peripheral = peripheral
        characteristics = service.characteristics
        let string = "00201200089950-1"
//        let string = "off"

        let data = string.data(using: String.Encoding.utf8)


        for characteristic in service.characteristics as [CBCharacteristic]!
        {
            if(characteristic.uuid.uuidString == "0xFFF4")
            {
                print("sending data")
                peripheral.writeValue(data!, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                print("Sent")
            }
        }
        
    }
    /**********************************************************/
    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
        didReadPeripheral(peripheral, rssi: RSSI)
        
        delay(scanningDelay){
            peripheral.readRSSI()
        }
    }
    
    func didReadPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber){
        if let name = peripheral.name{
            
            items[name] = [
                "name":name,
                "rssi":rssi
            ]
        }
        tableView.reloadData()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        peripheral.readRSSI()
        
        
        /**********************************************************/
        print("**** SUCCESSFULLY CONNECTED TO GATEWAY!!!")
        print("discovered \(String(describing: peripheral))")
        peripheral.discoverServices(nil)
        /**********************************************************/
        
        
    }
}

func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

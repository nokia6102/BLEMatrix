//
//  BLEController.h
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//

// reference from Framework Core Bluetooth
// https://developer.apple.com/documentation/corebluetooth

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface deviceData : NSObject {
}

@property (nonatomic, assign) NSString* Name;
@property (nonatomic, copy) NSString* Uuid;
@property (nonatomic, assign) NSNumber* Rssi;
@end

@interface propertyData : NSObject {
}

@property (nonatomic, assign) UInt32 service;
@property (nonatomic, assign) UInt32 notify;
@property (nonatomic, assign) UInt32 read;
@property (nonatomic, assign) UInt32 write;
@property (nonatomic, assign) UInt32 readWrite;
@end

@protocol BLEScanDelegate
- (void) deviceFound:(deviceData *)device;
- (void) devicePowerState:(Boolean)on;
- (void) deviceConnected;
@end

@protocol BLECtrlDelegate
- (void) dataUpdated:(NSData *)data UUID:(NSString *)UUID;
@end

@interface BLEController : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate> {
    UInt32 PropertyService;
    UInt32 PropertyNotify;
    UInt32 PropertyRead;
    UInt32 PropertyWrite;
}

@property (nonatomic, assign) id <BLEScanDelegate> delegateScan;
@property (nonatomic, assign) id <BLECtrlDelegate> delegateCtrl;
@property (strong, nonatomic) NSMutableArray * propertyArray;
@property (strong, nonatomic) NSMutableArray * peripherals;
@property (strong, nonatomic) CBCentralManager * manager;
@property (strong, nonatomic) CBPeripheral * activePeripheral;


// Methods for control BLE device
-(void) open;
-(int) scanDevices:(int)timeout;
-(void) scanTimer: (NSTimer *)timer;

-(Boolean) isActive;
-(void) setActive:(NSUInteger) index;
-(void) connect;
-(void) disconnect;
-(void) setProperty:(NSUInteger)index;

-(void) write:(NSData *)data;
-(void) read;
-(void) notify:(BOOL)on;


// private Methods
- (void) printPeripheralInfo:(CBPeripheral*)peripheral;
-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on;
-(UInt16) swap:(UInt16)s;

-(CBService *) findServiceFromUUIDEx:(CBUUID *)UUID p:(CBPeripheral *)p;
-(CBCharacteristic *) findCharacteristicFromUUIDEx:(CBUUID *)UUID service:(CBService*)service;
-(NSString *) UUIDToString:(NSUUID *) UUID;
-(NSString *) CBUUIDToString:(CBUUID *) UUID;
-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
-(int) compareCBUUIDToInt:(CBUUID *) UUID1 UUID2:(UInt16)UUID2;
-(UInt16) CBUUIDToInt:(CBUUID *) UUID;
-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;
-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p;

@end

//
//  BLEController.m
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//

#import "BLEController.h"

@implementation deviceData
@synthesize Name;
@synthesize Uuid;
@synthesize Rssi;
@end

@implementation propertyData
@synthesize service;
@synthesize notify;
@synthesize read;
@synthesize write;
@end

@implementation BLEController

@synthesize delegateScan;
@synthesize delegateCtrl;
@synthesize peripherals;
@synthesize manager;
@synthesize activePeripheral;
@synthesize propertyArray;


//
// -(void) open
// enable CoreBluetooth CentralManager and set the delegate for BLEController
//

-(void) open
{
    PropertyService = 0;
    PropertyNotify = 0;
    PropertyRead = 0;
    PropertyWrite = 0;
    delegateScan = nil;
    delegateCtrl = nil;

    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    propertyArray = [[NSMutableArray alloc] init];
}

//
// -(int) scanDevices:(int)timeout
//

-(int) scanDevices:(int)timeout
{
    //CBCentralManagerStatePoweredOn
    if ([manager state] != CBManagerStatePoweredOn) {
        
        NSLog(@"CoreBluetooth is not correctly initialized !");
        return -1;
    }
    
    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    //[manager scanForPeripheralsWithServices:[NSArray arrayWithObject:serviceUUID] options:0];
    
    // start Scanning
    [manager scanForPeripheralsWithServices:nil options:0];
    return 0;
}

//
// -(void) scanTimer:(NSTimer *)timer
// when findDevices is timeout, this function will be called
//

-(void) scanTimer:(NSTimer *)timer
{
    [manager stopScan];
}

-(Boolean) isActive
{
    return self.activePeripheral != nil;
}

-(void) setActive:(NSUInteger) index
{
    if(index > [peripherals count] - 1)
        return;

    self.activePeripheral = [peripherals objectAtIndex:index];
}

//
// connect to a active device
//

-(void) connect
{
    NSLog(@"begin connect");
    if([propertyArray count])
        [propertyArray removeAllObjects];

    if ( ! (activePeripheral.state == CBPeripheralStateConnected) )
        [manager connectPeripheral:activePeripheral options:nil];
}

//
// disconnect to a active device
//

-(void) disconnect
{
    NSLog(@"begin disconnect");
    [manager cancelPeripheralConnection:activePeripheral];
    activePeripheral = nil;
    
    [propertyArray removeAllObjects];
}

-(void) write:(NSData *)data
{
    NSLog(@"begin write, Property:%x", (unsigned int)PropertyWrite);
    [self writeValue:PropertyService characteristicUUID:PropertyWrite p:activePeripheral data:data];
}

-(void) read
{
    NSLog(@"begin read, Property:%x", (unsigned int)PropertyRead);
    [self readValue:PropertyService characteristicUUID:PropertyRead p:activePeripheral];
}

-(void) notify:(BOOL)on
{
    NSLog(@"begin notify, Property:%x Enable:%d", (unsigned int)PropertyService, on);
    [self notification:PropertyService characteristicUUID:PropertyNotify p:activePeripheral on:on];
}

-(void) setProperty:(NSUInteger)index
{
    if(index > [propertyArray count] - 1)
        return;

    propertyData* data = [propertyArray objectAtIndex:index];
    PropertyService = data.service;
    PropertyNotify = data.notify;

    if(data.read == 0 && data.readWrite > 0 )
        PropertyRead = data.readWrite;
    else
        PropertyRead = data.read;

    if(data.write == 0 && data.readWrite > 0 )
        PropertyWrite = data.readWrite;
    else
        PropertyWrite = data.write;
}

//
// Finding CBServices and CBCharacteristics
//

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)peripheral
{
    NSLog(@"the services count is %lu", peripheral.services.count);
    for (CBService *s in peripheral.services)
    {
        NSLog(@"%@ is found!", s.UUID.UUIDString);
        // compare s with UUID
        if ([[s.UUID data] isEqualToData:[UUID data]])
            return s;
    }
    return  nil;
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID p:(CBPeripheral *)peripheral service:(CBService *)service
{
    for (CBCharacteristic *c in service.characteristics)
    {
        NSLog(@"characteristic <%@> is found!", UUID.UUIDString);
        if ([[c.UUID data] isEqualToData:[UUID data]])
            return c;
    }
    return nil;
}


// implementation CBCentralManager Delegates

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //TODO: to handle the state updates
    NSMutableString* nsmstring=[NSMutableString stringWithString:@"UpdateState:"];
    Boolean isWork = false;
    
    switch (central.state) {
        case CBManagerStateUnknown:
            [nsmstring appendString:@"Unknown\n"];
            break;
        case CBManagerStateUnsupported:
            [nsmstring appendString:@"Unsupported\n"];
            break;
        case CBManagerStateUnauthorized:
            [nsmstring appendString:@"Unauthorized\n"];
            break;
        case CBManagerStateResetting:
            [nsmstring appendString:@"Resetting\n"];
            break;
        case CBManagerStatePoweredOff:
            [nsmstring appendString:@"PoweredOff\n"];
            if (activePeripheral !=  nil)
                [central cancelPeripheralConnection:activePeripheral];
            break;
        case CBManagerStatePoweredOn:
            [nsmstring appendString:@"PoweredOn\n"];
            isWork = true;
            break;
        default:
            [nsmstring appendString:@"none\n"];
            break;
    }
    NSLog(@"%@",nsmstring);
    
    if(delegateScan != nil)
        [delegateScan devicePowerState:isWork];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Now found device");
    NSMutableString* nsstr = [NSMutableString stringWithString:@"\n"];
    [nsstr appendFormat:@"Name: %@, RSSI:%@", peripheral.name, RSSI];
    NSLog(@"%@", nsstr);
    NSLog(@"Adverisement:%@", advertisementData);
    
    if (!peripherals)
        peripherals = [[NSMutableArray alloc] init];
    
    if( peripheral.identifier == NULL)
        return;
    
    // Add the new peripheral to the peripherals array
    NSString* uuid1;
    NSString* uuid2;
    for (int i = 0; i < [peripherals count]; i++)
    {
        CBPeripheral *p = [peripherals objectAtIndex:i];
        if(p.identifier == NULL)
            continue;
        
        uuid1 = p.identifier.UUIDString;
        uuid2 = peripheral.identifier.UUIDString;

        if( [uuid1 isEqualToString:uuid2] )
        {
            // these are the same, and replace the old peripheral information
            [peripherals replaceObjectAtIndex:i withObject:peripheral];
            NSLog(@"Duplicated peripheral is found...");
            return;
        }
    }
    
    NSLog(@"New peripheral is found...");
    [peripherals addObject:peripheral];

    deviceData* data = [[deviceData alloc] init];
    data.Name = peripheral.name;
    data.Uuid = peripheral.identifier.UUIDString;
    data.Rssi = RSSI;

    if( delegateScan != nil )
        [delegateScan deviceFound:data];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    activePeripheral = peripheral;
    activePeripheral.delegate = self;
    
    [activePeripheral discoverServices:nil];
    [self printPeripheralInfo:peripheral];
    
    NSLog(@"connected to the active peripheral");
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    activePeripheral = nil;
    NSLog(@"disconnected to the active peripheral");
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"failed to connect to peripheral %@: %@\n", [peripheral name], [error localizedDescription]);
}


// implementation CBPeripheral delegates

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"begin updateValueForCharacteristic function");
    
    if (error)
    {
        NSLog(@"updateValueForCharacteristic failed");
        return;
    }
    
    NSString* str = [[NSString alloc] initWithFormat:@"%@", characteristic.UUID.UUIDString];
    
    if( delegateCtrl != nil )
        [delegateCtrl dataUpdated:characteristic.value UUID:str];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"begin didWriteValueForCharacteristic function");
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"begin didWriteValueForDescriptor function");
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"begin peripheralDidUpdateRSSI function");
}


/*
 *  @method didDiscoverServices
 *
 *  @param peripheral Pheripheral that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverServices is called when CoreBluetooth has discovered services on a
 *  peripheral after the discoverServices routine has been called on the peripheral
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error)
    {
        NSLog(@"Services of peripheral with UUID : %@ found",[self UUIDToString:peripheral.identifier]);
        [self getAllCharacteristicsFromKey:peripheral];
    }
    else
    {
        NSLog(@"Service discovery was unsuccessfull !");
    }
}

/*
 *  @method getAllCharacteristicsFromKey
 *
 *  @param p Peripheral to scan
 *
 *
 *  @discussion getAllCharacteristicsFromKey starts a characteristics discovery on a peripheral
 *  pointed to by p
 *
 */

-(void) getAllCharacteristicsFromKey:(CBPeripheral *)p
{
    for (int i=0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        NSLog(@"Fetching characteristics for service with UUID : %@", s.UUID.UUIDString);
        [p discoverCharacteristics:nil forService:s];
    }
}

/*
 *  @method didDiscoverCharacteristicsForService
 *
 *  @param peripheral Pheripheral that got updated
 *  @param service Service that characteristics where found on
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverCharacteristicsForService is called when CoreBluetooth has discovered
 *  characteristics on a service, on a peripheral after the discoverCharacteristics routine has been called on the service
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error)
    {
        propertyData *data = [[propertyData alloc] init];

        NSString * serviceUuid = [NSString stringWithFormat:@"0x%@", [service UUID].UUIDString];
        NSLog(@"Characteristics of service with UUID : %@ found",serviceUuid);
        
        unsigned int hexValue = 0;
        NSScanner* scanner = [NSScanner scannerWithString:serviceUuid];
        [scanner scanHexInt:&hexValue];
        data.service = hexValue;
        
        NSLog(@"Property: service, %x", (unsigned int)data.service);
        for(int i=0; i < service.characteristics.count; i++)
        {
            CBCharacteristic *c = [service.characteristics objectAtIndex:i];
            UInt32 uuid;
            NSString* str = [NSString stringWithFormat:@"0x%@", [c UUID].UUIDString];
            scanner = [NSScanner scannerWithString:str];
            [scanner scanHexInt:&uuid];
            
            uint32_t property = [c properties];
            if( property == (CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite) )
            {
                data.readWrite = uuid;
                NSLog(@"Property: PropertyReadWrite:%x", (unsigned int)data.readWrite);
            }
            else if( property == CBCharacteristicPropertyRead )
            {
                data.read = uuid;
                NSLog(@"Property: PropertyRead:%x", (unsigned int)data.read);
            }
            else if( ( property == (CBCharacteristicPropertyWrite | CBCharacteristicPropertyWriteWithoutResponse) ) ||
                     ( property == CBCharacteristicPropertyWrite ) )
            {
                data.write = uuid;
                NSLog(@"Property: PropertyWrite:%x", (unsigned int)data.write);
            }
            else if( property == CBCharacteristicPropertyNotify )
            {
                data.notify = uuid;
                NSLog(@"Property: PropertyNotify:%x", (unsigned int)data.notify);
            }
            else if( property == (CBCharacteristicPropertyRead | CBCharacteristicPropertyWriteWithoutResponse| CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify))
            {
                data.read = uuid;
                data.write = uuid;
                data.notify = uuid;
            }
            
            NSLog(@"Found characteristic:%@, property:%x",[ self CBUUIDToString:c.UUID], property);
        }

        [propertyArray addObject:data];
        if( delegateScan != nil)
        {
            if( [propertyArray count] >= [[peripheral services] count] )
               [delegateScan deviceConnected];
        }
    }
    else
    {
        NSLog(@"Characteristic discorvery unsuccessfull !");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error)
    {
        NSLog(@"Updated notification state for characteristic with UUID %@ on service with  UUID %@ on peripheral with UUID %@",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.identifier]);
    }
    else
    {
        NSLog(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.identifier]);
        NSLog(@"Error code was %@",[error description]);
    }
}

/*!
 *  @method notification:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0xFFE0)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0xFFE1)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for enabling and disabling notification services. It converts integers
 *  into CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the notfication is set.
 *
 */

-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];

    CBService *service = [self findServiceFromUUIDEx:su p:p];
    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",[self CBUUIDToString:su],[self UUIDToString:p.identifier]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:p.identifier]);
        return;
    }
    [p setNotifyValue:on forCharacteristic:characteristic];
}

/*
 *  @method printPeripheralInfo:
 *
 *  @param peripheral Peripheral to print info of
 *
 *  @discussion printPeripheralInfo prints detailed info about peripheral
 *
 */
- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
    CFStringRef uuid = (__bridge CFStringRef)peripheral.identifier.UUIDString;
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");
    NSLog(@"UUID: %@", uuid);
    NSLog(@"Name: %@", peripheral.name);
    NSLog(@"Is Connected: %d", (peripheral.state == CBPeripheralStateConnected));
    NSLog(@"------------------------------------");
}

/*
 *  @method CBUUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer
 *
 */
-(NSString *) CBUUIDToString:(CBUUID *) UUID
{
    return UUID.UUIDString;
}


/*
 *  @method UUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion UUIDToString converts the data of a CFUUIDRef class to a character pointer for easy printout using printf()
 *
 */
-(NSString *) UUIDToString:(NSUUID *)UUID
{
    return UUID.UUIDString;
}

/*
 *  @method compareCBUUID
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
 *
 */

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    if( [UUID1.UUIDString isEqualToString:UUID2.UUIDString] )
        return 1;

    return 0;
}

/*
 *  @method compareCBUUIDToInt
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UInt16 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUIDToInt compares a CBUUID to a UInt16 representation of a UUID and returns 1 
 *  if they are equal and 0 if they are not
 *
 */

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
    unsigned char b1[16];
    [UUID1.data getBytes:b1 length:sizeof(b1)];
    UInt16 b2 = [self swap:UUID2];

    if (memcmp(b1, (char *)&b2, 2) == 0)
        return 1;

    return 0;
}

/*
 *  @method CBUUIDToInt
 *
 *  @param UUID1 UUID 1 to convert
 *
 *  @returns UInt16 representation of the CBUUID
 *
 *  @discussion CBUUIDToInt converts a CBUUID to a Uint16 representation of the UUID
 *
 */
-(UInt16) CBUUIDToInt:(CBUUID *) UUID
{
    unsigned b1[16];
    [UUID.data getBytes:b1 length:sizeof(b1)];

    return ((b1[0] << 8) | b1[1]);
}

/*
 *  @method IntToCBUUID
 *
 *  @param UInt16 representation of a UUID
 *
 *  @return The converted CBUUID
 *
 *  @discussion IntToCBUUID converts a UInt16 UUID to a CBUUID
 *
 */

-(CBUUID *) IntToCBUUID:(UInt16)UUID
{
    char t[16] = {0};
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];

    return [CBUUID UUIDWithData:data];
}

/*
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

-(UInt16) swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

/*
 *  @method findServiceFromUUID:
 *
 *  @param UUID CBUUID to find in service list
 *  @param p Peripheral to find service on
 *
 *  @return pointer to CBService if found, nil if not
 *
 *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a 
 *  service with a specific UUID
 *
 */

-(CBService *) findServiceFromUUIDEx:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }

    return nil; //Service not found on this peripheral
}

/*
 *  @method findCharacteristicFromUUID:
 *
 *  @param UUID CBUUID to find in Characteristic list of service
 *  @param service Pointer to CBService to search for charateristics on
 *
 *  @return pointer to CBCharacteristic if found, nil if not
 *
 *  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service 
 *  to find a characteristic with a specific UUID
 *
 */

-(CBCharacteristic *) findCharacteristicFromUUIDEx:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID])
            return c;
    }

    return nil; //Characteristic not found on this service
}


/*!
 *  @method writeValue:
 *
 *  @param serviceUUID Service UUID to write to (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to write to (e.g. 0x2401)
 *  @param data Data to write to peripheral
 *  @param p CBPeripheral to write to
 *
 *  @discussion Main routine for writeValue request, writes without feedback. It converts integer into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service. 
 *  If this is found, value is written. If not nothing is done.
 *
 */

-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUIDEx:su p:p];
    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",[self CBUUIDToString:su],[self UUIDToString:p.identifier]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:p.identifier]);
        return;
    }

    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}


/*!
 *  @method readValue:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for read value request. It converts integers into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service. 
 *  If this is found, the read value is started. When value is read the didUpdateValueForCharacteristic 
 *  routine is called.
 *
 *  @see didUpdateValueForCharacteristic
 */

-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p
{
    printf("In read Value");
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUIDEx:su p:p];
    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",[self CBUUIDToString:su],[self UUIDToString:p.identifier]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:p.identifier]);
        return;
    }  
    [p readValueForCharacteristic:characteristic];
}

@end

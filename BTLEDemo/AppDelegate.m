#import "AppDelegate.h"

#define CHARPROPS CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify
#define CHARACCESS CBAttributePermissionsReadable|CBAttributePermissionsWriteable

@interface AppDelegate ()

// The window
@property (weak) IBOutlet NSWindow *window;

// The Slider containing a value between 0-100
@property (assign) IBOutlet NSSlider *volume;

// A name that can be written
@property (assign) IBOutlet NSTextField *name;

// A name that can be written
@property (assign) IBOutlet NSButton *advertising;

// The peripheral manager
@property (retain) IBOutlet CBPeripheralManager *cpManager;


// The name characteristics
@property (readonly) CBMutableService* service;


// The name characteristics
@property (readonly) CBMutableCharacteristic* nameCharacteristics;

// The volume characteristics
@property (readonly) CBMutableCharacteristic* volumeCharacteristics;

// The service UUID
@property (readonly) CBUUID* serviceUUID ;

// The name UUID
@property (readonly) CBUUID* nameUUID ;

// The volume UUID
@property (readonly) CBUUID* volumeUUID ;

@property (readonly) NSDictionary* advertisingValues;

@end

@implementation AppDelegate {
    bool canUpdate;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Set the UUIDs
    _serviceUUID = [CBUUID UUIDWithString:@"8436054B-047E-494B-9EC0-E6B9E2ADF8EE"];
    _nameUUID = [CBUUID UUIDWithString:@"2C1CF75D-751C-4ED8-A478-884BDCDCBD75"];
    _volumeUUID = [CBUUID UUIDWithString:@"D5BB9776-B58F-44D4-AF28-13DE24BE71ED"];
    
    // Create the service
    _service = [[CBMutableService alloc] initWithType:_serviceUUID primary:YES];
    
    // Create the characteristics
    _nameCharacteristics = [[CBMutableCharacteristic alloc] initWithType:_nameUUID properties:CHARPROPS value:nil permissions:CHARACCESS];
    _volumeCharacteristics = [[CBMutableCharacteristic alloc] initWithType:_volumeUUID properties:CHARPROPS value:nil permissions:CHARACCESS];
    
    // Set characteristics on service
    _service.characteristics = @[
                                 _nameCharacteristics,
                                 _volumeCharacteristics
                                 ];
    
    // Create the periperal manager
    _cpManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    _advertisingValues = @{ CBAdvertisementDataLocalNameKey: @"CPHDroidDev",
                                         CBAdvertisementDataServiceUUIDsKey : @[_serviceUUID] };
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self unpublishService];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state==CBPeripheralManagerStatePoweredOn) {
        [self publishService];
        [_advertising setEnabled:YES];
        [_name setEnabled:YES];
        [_volume setEnabled:YES];
    } else {
        [_advertising setTitle:@"Start Advertising"];
        [self unpublishService];
        [_advertising setEnabled:NO];
        [_name setEnabled:NO];
        [_volume setEnabled:NO];
    }
    canUpdate = false;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    
    
    if ([request.characteristic.UUID isEqualTo:_volumeUUID]) {
        int32_t volumeLevel = [_volume intValue];
        NSLog(@"Volume read request %d", volumeLevel);
        request.value = [NSData dataWithBytes: &volumeLevel length: sizeof(volumeLevel)];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        
    } else if ([request.characteristic.UUID isEqualTo:_nameUUID]) {
        NSString* nameValue = [_name stringValue] ;
        NSLog(@"Name read request %@", nameValue);
        request.value = [nameValue dataUsingEncoding:NSUTF8StringEncoding];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        
    } else {
        NSLog(@"Could not perform read request");
        [peripheral respondToRequest:request withResult:CBATTErrorRequestNotSupported];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    for (CBATTRequest* r in requests) {
        if ([r.characteristic.UUID isEqualTo:_volumeUUID]) {
            int32_t value = *((int32_t*)r.value.bytes);
            NSLog(@"Volume write request %d", value);
            [_volume setIntValue: value];
            [peripheral respondToRequest:r withResult:CBATTErrorSuccess];
            
        } else if ([r.characteristic.UUID isEqualTo:_nameUUID]) {
            NSString* nameValue;
            if (r.value.length>0) {
                nameValue = [NSString stringWithUTF8String:(const char*)r.value.bytes];
            } else {
                nameValue = @"";
            }
            NSLog(@"Name read request %@", nameValue);
            [_name setStringValue:nameValue];
            [peripheral respondToRequest:r withResult:CBATTErrorSuccess];
            
        } else {
            [peripheral respondToRequest:r withResult:CBATTErrorRequestNotSupported];
        }
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    NSLog(@"Service added");    
}

-(void)publishService {
    [_cpManager addService:_service];
}

-(void)unpublishService {
    [_cpManager removeService:_service];
}

-(IBAction)handleValueChanged: sender {
    int32_t volumeLevel = [_volume intValue];
    NSLog(@"Volume changed %d", volumeLevel);
    NSData *data = [NSData dataWithBytes: &volumeLevel length: sizeof(volumeLevel)];
    [_cpManager updateValue:data forCharacteristic:_volumeCharacteristics onSubscribedCentrals:nil];
}

-(IBAction)handleNameChanged: sender {
    NSString* nameValue = [_name stringValue] ;
    NSLog(@"Name changed %@", nameValue);
    [_cpManager updateValue:[nameValue dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_nameCharacteristics onSubscribedCentrals:nil];

}

-(IBAction)startAdvertising: sender {
    if (_advertising.isEnabled) {
        if ([_advertising.title isEqualToString:@"Start Advertising"]) {
            
            [_cpManager startAdvertising:_advertisingValues];
            [_advertising setTitle:@"Stop Advertising"];
        } else {
            [_cpManager stopAdvertising];
            [_advertising setTitle:@"Start Advertising"];
        }
    }
}


@end

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, CBPeripheralManagerDelegate>


-(IBAction)handleValueChanged: sender;

-(IBAction)handleNameChanged: sender;

-(IBAction)startAdvertising: sender;


@end


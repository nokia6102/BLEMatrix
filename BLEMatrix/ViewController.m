//
//  ViewController.m
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/NSText.h>

#import "ViewController.h"
#import "OperatorViewController.h"
#import "SettingViewController.h"
#import "BLEController.h"

#define SCAN_TIME 5
#define RSSI_RATE -30
//#define kWidth [UIScreen mainScreen].bounds.size.width

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, BLEScanDelegate>
@property (strong, nonatomic) IBOutlet UITableView *DeviceTableView;
@property (strong, nonatomic) BLEController* ooBLEctrl;
@property (strong, nonatomic) SettingViewController* settingView;
@property settingData* data;
@end

@implementation ViewController

@synthesize deviceArray;
@synthesize settingView;

NSTimer *connectTimer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    connectTimer = nil;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.DeviceTableView.delegate = self;
    self.DeviceTableView.dataSource = self;
    
    self.BLEctrl = [[BLEController alloc] init];
    [self.BLEctrl open];
    self.BLEctrl.delegateScan = self;

    deviceArray = [[NSMutableArray alloc] init];
//    self.operatorView = [[OperatorViewController alloc] init];
//    self.operatorView.BLEctrl = self.BLEctrl;

    self.data = [[settingData alloc] init];
    self.data.enableFilter = false;
    self.data.scanTime = SCAN_TIME;
    self.data.rssi = RSSI_RATE;
//    self.settingView = [[SettingViewController alloc] init];
//    self.settingView.data = self.data;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//
// implementation table view delegate
//

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.deviceArray count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.BLEctrl.manager stopScan];
    NSUInteger row = [indexPath row];

    
    
    if ([self.BLEctrl isActive])
        [self.BLEctrl disconnect];

    [self.BLEctrl setActive:row];
    [self.BLEctrl connect];

    //
    // wait a while for device connection
    //
    connectTimer = [NSTimer scheduledTimerWithTimeInterval:self.data.scanTime target:self selector:@selector(connectTimer:) userInfo:nil repeats:NO];

    [self.connectIndicatorView setFrame:[[tableView cellForRowAtIndexPath:indexPath] frame]];
    [self.connectIndicatorView startAnimating];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellId = @"peripheral";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if ( cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];

    // Configure the cell
    NSUInteger row = [indexPath row];
    deviceData* device = [deviceArray objectAtIndex:row];
    NSString *str = [NSString stringWithFormat:@"%@, %d dB", (device.Name ? device.Name : @"Unknown"), (int)[device.Rssi integerValue]];
    cell.textLabel.text = str;
    cell.detailTextLabel.text = device.Uuid ? device.Uuid : @"Unknown";
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}

//
// implementation BLECtrlDelegate
//

- (void) deviceFound:(deviceData*)device
{
    if(self.data.enableFilter)
    {
        if( self.data.rssi < [device.Rssi integerValue])
            [deviceArray addObject:device];
    }
    else
    {
        [deviceArray addObject:device];
    }

    [self.DeviceTableView reloadData];
}

- (void) devicePowerState:(Boolean)on
{
    if(on)
        return;

    [self AlertMessage:@"Please turn on the Bluetooth device."];
}

- (void) deviceConnected
{
    [connectTimer invalidate];
    connectTimer = nil;
    
    [self.connectIndicatorView stopAnimating];
    //OperatorViewController* viewController = [operatorViewControllerArray objectAtIndex:row];
    //[self.navigationController pushViewController:self.operatorView animated:YES];
    UIStoryboard *storyboard=[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    OperatorViewController *operatorView = [storyboard instantiateViewControllerWithIdentifier:@"operatorView"];
    operatorView.BLEctrl = self.BLEctrl;
    [self.navigationController pushViewController:operatorView animated:YES];
}

//
//
//

- (IBAction)settingAction:(id)sender
{
//    [self.navigationController pushViewController:self.settingView animated:YES];
    UIStoryboard *storyboard=[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SettingViewController *settingView = [storyboard instantiateViewControllerWithIdentifier:@"settingView"];
    settingView.data = self.data;
    [self.navigationController pushViewController:settingView animated:YES];
}

- (IBAction)scanDevice:(id)Scan
{
    
    if ([self.BLEctrl activePeripheral])
    {
        if (self.BLEctrl.activePeripheral.state == CBPeripheralStateConnected)
        {
            [self.BLEctrl.manager cancelPeripheralConnection:self.BLEctrl.activePeripheral];
            self.BLEctrl.activePeripheral = nil;
        }
    }
    
    // clean peripherals arrary
    if ([self.BLEctrl peripherals])
    {
        self.BLEctrl.peripherals = nil;
        [self.BLEctrl.peripherals removeAllObjects];

        [self.deviceArray removeAllObjects];
        [self.DeviceTableView reloadData];
        
//        [operatorViewControllerArray removeAllObjects];
    }
    
    //self.BLEctrl.delegate = self;
    NSLog(@"now we are searching device...");
    //[Scan setTitle:@"Scanning" forState:UIControlStateNormal];
    [self.BtnScanDev setTitle:@"Scanning"];
    
    [NSTimer scheduledTimerWithTimeInterval:self.data.scanTime target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    [self.BLEctrl scanDevices:5];
}

-(void) scanTimer:(NSTimer *)timer
{
   // [self.BtnScanDev setTitle:@"Scan" forState:UIControlStateNormal];
    [self.BtnScanDev setTitle:@"Scan"];
    
    if([deviceArray count] == 0)
        [self AlertMessage:@"Can not find any BLE device."];
}

-(void) connectTimer:(NSTimer *)timer
{
    if ([self.BLEctrl isActive])
        [self.BLEctrl disconnect];

    connectTimer = nil;
    [self.connectIndicatorView stopAnimating];
    [self AlertMessage:@"Fail to connect BLE device."];
}

- (void)AlertMessage:(NSString*) msg
{
//    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Information" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//    [alert show];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Information" message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

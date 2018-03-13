//
//  SettingViewController.m
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//


#import <UIKit/NSText.h>
#import "SettingViewController.h"

@implementation settingData
@synthesize scanTime;
@synthesize rssi;
@synthesize enableFilter;
@end

@interface SettingViewController ()

@end

@implementation SettingViewController

@synthesize data;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.rssiSlider.enabled = self.data.enableFilter;
    self.filterSwitch.on = self.data.enableFilter;
    [self.rssiSlider setValue:self.data.rssi];
    NSString* str = [NSString stringWithFormat:@"%d", (int)self.data.rssi];
    self.rssiLabel.text = str;
    
    [self.scanTimeSlider setValue:self.data.scanTime];
    str = [NSString stringWithFormat:@"%d", (int)self.data.scanTime];
    self.scanTimeLabel.text = str;
    str = [NSString stringWithFormat:@"%d", (int)self.data.rssi];
    self.rssiLabel.text = str;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)rssiTouchUpInside:(id)sender
{
    UISwitch *sw = (UISwitch*)sender;
    self.rssiSlider.enabled = sw.on;
    self.data.enableFilter = sw.on;
}

- (IBAction)scanTimeValueChanged:(id)sender
{
    UISlider *slider = (UISlider*)sender;
    NSString* str = [NSString stringWithFormat:@"%d", (int)slider.value];
    self.scanTimeLabel.text = str;
    self.data.scanTime = (int)slider.value;
}

- (IBAction)rssiValueChanged:(id)sender
{
    UISlider *slider = (UISlider*)sender;
    NSString* str = [NSString stringWithFormat:@"%d", (int)slider.value];
    self.rssiLabel.text = str;
    self.data.rssi = (int)slider.value;
}
@end

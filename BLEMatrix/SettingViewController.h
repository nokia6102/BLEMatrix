//
//  SettingViewController.h
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface settingData : NSObject {
}

@property (readwrite, nonatomic) NSInteger scanTime;
@property (readwrite, nonatomic) NSInteger rssi;
@property (readwrite, nonatomic) Boolean enableFilter;
@end

@interface SettingViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *scanTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UISwitch *filterSwitch;
@property (weak, nonatomic) IBOutlet UISlider *rssiSlider;
@property (weak, nonatomic) IBOutlet UISlider *scanTimeSlider;

@property (strong, nonatomic) settingData* data;

- (IBAction)rssiTouchUpInside:(id)sender;
- (IBAction)scanTimeValueChanged:(id)sender;
- (IBAction)rssiValueChanged:(id)sender;
@end

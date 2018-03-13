//
//  OperatorViewController.h
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLEController;

@interface cmdData:NSObject {
}

@property (strong, nonatomic) NSString* Title;
@property (strong, nonatomic) NSString* Cmd;
@end

@interface OperatorViewController : UIViewController

@property (strong, nonatomic) BLEController* BLEctrl;
@property (nonatomic, retain) NSMutableArray *cmdArray;
@property (weak, nonatomic) IBOutlet UITableView *cmdTableView;
@property (weak, nonatomic) IBOutlet UITextView *msgTextView;
@property (weak, nonatomic) IBOutlet UISwitch *switchLfCr;
@property (weak, nonatomic) IBOutlet UIPickerView *servicePickView;


- (IBAction)stepper:(id)sender;
- (IBAction)ClearMsg:(id)sender;

@end

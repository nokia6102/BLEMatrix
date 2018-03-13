//
//  ViewController.h
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController

@property (nonatomic, retain) NSMutableArray *deviceArray;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *BtnScanDev;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *connectIndicatorView;

- (IBAction)settingAction:(id)sender;
- (IBAction)scanDevice:(id)Scan;
- (void)AlertMessage:(NSString*) msg;
@end


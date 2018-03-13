//
//  OperatorViewController.m
//  BLEMatrix
//
//  Created by jason on 17/11/2017.
//  Copyright © 2017 jason. All rights reserved.
//


#import <UIKit/NSText.h>
#import "OperatorViewController.h"
#import "BLEController.h"

#define kCmdList @"CmdList"

@implementation cmdData
@synthesize Title;
@synthesize Cmd;
@end


@interface OperatorViewController () <UITableViewDataSource, UITableViewDelegate,UIPickerViewDataSource, UIPickerViewDelegate, BLECtrlDelegate>

@property (strong, nonatomic) NSString *msg;
@property NSUInteger stepValue;
@end

@implementation OperatorViewController

@synthesize BLEctrl;
@synthesize cmdArray;

NSInteger currentRow;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.BLEctrl.delegateCtrl = self;

    self.cmdArray = [[NSMutableArray alloc] init];
    self.cmdTableView.delegate = self;
    self.cmdTableView.dataSource = self;

    self.servicePickView.dataSource = self;
    self.servicePickView.delegate = self;
    self.servicePickView.showsSelectionIndicator = YES;
    
    self.stepValue = 0;
    currentRow = -1;

    [self.servicePickView reloadAllComponents];
    [self.servicePickView selectRow:0 inComponent:0 animated:YES];
    [BLEctrl setProperty:0];
    [BLEctrl notify:YES];

    //restore configure
    [self loadCmdInfo];
    [self.cmdTableView reloadData];
}

- (void)viewWillDisappear:(BOOL) b
{
    [super viewWillDisappear:b];
    [BLEctrl disconnect];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cmdArray count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    cmdData* cmd = [cmdArray objectAtIndex:row];
    NSString* str;
    if(self.switchLfCr.on)
        str = [NSString stringWithFormat:@"%@\n\r", cmd.Cmd];
    else
        str = cmd.Cmd;

    NSData *data = [str dataUsingEncoding:[NSString defaultCStringEncoding]];
    [BLEctrl write:data];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"command";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if ( cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];

    // Configure the cell
    NSUInteger row = [indexPath row];
    cmdData* cmd = [cmdArray objectAtIndex:row];
    NSString* str = [NSString stringWithFormat:@"%lu. %@", (unsigned long)row + 1, cmd.Title];
    cell.textLabel.text = str;
    //cell.detailTextLabel.text = cmd.Cmd ? cmd.Cmd : @"Unknown";
    cell.accessoryType = UITableViewCellAccessoryNone;//UITableViewCellAccessoryCheckmark;

    return cell;
}

//
// implementation pick view delegate
//
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component) {
        case 0:
            return [BLEctrl.propertyArray count];
            break;

        default:
            return 0;
            break;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    propertyData* data = [BLEctrl.propertyArray objectAtIndex:row];
    switch (component) {
        case 0:
            return [NSString stringWithFormat:@"%x",(unsigned int)data.service];
            break;

        default:
            return @"Error";
            break;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(currentRow == row)
        return;

    // unregister first
    [BLEctrl notify:NO];
    [BLEctrl setProperty:row];
    [BLEctrl notify:YES];
    currentRow = row;
}


//
// implementation BLECtrlDelegate
//
- (void) dataUpdated:(NSData *)data UUID:(NSString *)UUID
{
    // read data from BLE device
    NSMutableString* tmp = [[NSMutableString alloc] init];
    [tmp appendFormat:@"%@", self.msgTextView.text];
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"receive data:%@", str);
    [tmp appendFormat:@"%@", str];
    //[str stringByAppendingFormat:@"\r\n%@", tmp];
    NSLog(@"New TextView:%@", tmp);
    self.msgTextView.text = tmp;
}

//
//
//

- (IBAction)stepper:(id)sender
{
    UIStepper *stepper = (UIStepper *) sender;

    if (stepper.value > self.stepValue )
    {
        NSLog(@"+ %lu", (unsigned long)self.stepValue);

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Input Name and Command into TextFields" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            // optionally configure the text field
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.placeholder = @"Name";
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            // optionally configure the text field
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.placeholder = @"Command";
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            cmdData* cmd = [[cmdData alloc] init];
            UITextField *textTitle = [alertController.textFields objectAtIndex:0];
            cmd.Title = [textTitle text];
            UITextField *textCmd = [alertController.textFields objectAtIndex:1];
            cmd.Cmd = [textCmd text];
            
            if(! [cmd.Cmd isEqualToString:@""])
            {
                [cmdArray addObject:cmd];
                [self.cmdTableView reloadData];
                [self saveCmdInfo];
            }
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        NSLog(@"- %lu", (unsigned long)self.stepValue);
        
        NSIndexPath *path= [self.cmdTableView indexPathForSelectedRow];
        if(path != nil)
        {
           [cmdArray removeObjectAtIndex:[path row]];
           [self.cmdTableView reloadData];
        }
    }
    
    self.stepValue = stepper.value;
    
}

- (IBAction)ClearMsg:(id)sender
{
    self.msgTextView.text = @"";
}

//
// store user configuration
//

// loadInfo
-(void)loadCmdInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [defaults dictionaryForKey:kCmdList];

    if( dict != nil )
    {
        for (NSString *key in dict)
        {
            cmdData* data = [[cmdData alloc] init];
            data.Title = key;
            data.Cmd = dict[key];
            [cmdArray addObject:data];
        }
    }
}

// saveInfo
-(void)saveCmdInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for(int i = 0; i < cmdArray.count; ++ i)
    {
        cmdData* data = [cmdArray objectAtIndex:i];
        [dict setValue:data.Cmd forKey:data.Title];
    }

    [defaults setObject:dict forKey:kCmdList];
}

// clearInfo
-(void)clearCmdInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kCmdList];
}

@end

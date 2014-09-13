//
//  IAHSettingsViewController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHSettingsViewController.h"
#import "IAHNameController.h"
#import "IAHRegionController.h"

@interface IAHSettingsViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *clearUsernameButton;
@property (weak, nonatomic) IBOutlet UIButton *regionMonitoringButton;

@end

@implementation IAHSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.userNameTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Do any additional setup after loading the view.
    
    [self updateUI];
}

-(void)updateUI
{
    NSString *name = [[IAHNameController sharedManager] name];
    if([name length] > 0)
    {
        
        self.userNameLabel.text = [NSString stringWithFormat:@"Username: %@", name];
        self.clearUsernameButton.enabled = YES;
        self.regionMonitoringButton.enabled = YES;
    }
    else
    {
        self.userNameLabel.text = @"No Username Available";
        self.clearUsernameButton.enabled = NO;
        self.regionMonitoringButton.enabled = NO;
    }
    
    if([[IAHRegionController sharedManager] regionMonitoringEnabled])
        [self.regionMonitoringButton setTitle:@"Disable Region Monitoring" forState:UIControlStateNormal];
    else
        [self.regionMonitoringButton setTitle:@"Enable Region Monitoring" forState:UIControlStateNormal];
}

- (IBAction)regionMonitoringButtonPressed:(id)sender
{
    
    self.view.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    [activityIndicator startAnimating];
    activityIndicator.center = self.view.center;
    [self.view addSubview:activityIndicator];
    
    [[IAHRegionController sharedManager] setRegionMonitoring:![[IAHRegionController sharedManager] regionMonitoringEnabled] completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityIndicator removeFromSuperview];
            self.view.userInteractionEnabled = YES;
            self.tabBarController.tabBar.userInteractionEnabled = YES;
            [self updateUI];
        });
    }];
    
}

- (IBAction)clearUsernameButtonPressed:(id)sender
{
    self.view.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    [activityIndicator startAnimating];
    activityIndicator.center = self.view.center;
    [self.view addSubview:activityIndicator];
    [[IAHNameController sharedManager]setName:@"" completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityIndicator removeFromSuperview];
            self.view.userInteractionEnabled = YES;
            self.tabBarController.tabBar.userInteractionEnabled = YES;
            [self updateUI];
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma Mark - UITextViewDelegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
    NSString *name = textField.text;
    textField.text = @"";
    if([name length] > 0)
    {
        self.view.userInteractionEnabled = NO;
        self.tabBarController.tabBar.userInteractionEnabled = NO;
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.hidesWhenStopped = YES;
        [activityIndicator startAnimating];
        activityIndicator.center = self.view.center;
        [self.view addSubview:activityIndicator];
        [[IAHNameController sharedManager]setName:name completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityIndicator removeFromSuperview];
                self.view.userInteractionEnabled = YES;
                self.tabBarController.tabBar.userInteractionEnabled = YES;
                [self updateUI];
            });
        }];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

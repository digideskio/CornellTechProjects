//
//  IAHTabBarController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHTabBarController.h"
#import "IAHRegionController.h"
#import "IAHNameController.h"
#import "IAHCommunicationController.h"

@interface IAHTabBarController ()

@end

@implementation IAHTabBarController

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
    
    [IAHCommunicationController sharedController];
    
    NSString *name = [[IAHNameController sharedManager] name];
    if([name length] == 0)
    {
        [[IAHRegionController sharedManager] setRegionMonitoring:NO completion:^{
            __block UIViewController *settingsViewController = nil;
            [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                NSString *restorationID = ((UIViewController*)obj).restorationIdentifier;
                NSLog(@"%@", restorationID);
                if([restorationID isEqualToString:@"SettingsViewer"])
                {
                    settingsViewController = (UIViewController *)obj;
                    *stop = YES;
                }
            }];
            
            self.selectedViewController = settingsViewController;
            //alert that region monitoring will not begin until a name has been established
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"No User Name Available" message:@"Please enter a user name to begin region monitoring" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }];
    }
    else
        [[IAHRegionController sharedManager] setRegionMonitoring:YES completion:nil];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

//
//  IAHCurrentOccupancyViewController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHCurrentOccupancyViewController.h"
#import "IAHCommunicationController.h"

@interface IAHCurrentOccupancyViewController ()

@end

@implementation IAHCurrentOccupancyViewController

-(void)fetchOccupancy:(completionBlockWithResponseObject)complete
{
    IAHCommunicationController *controller = [IAHCommunicationController sharedController];
    [controller getCurrentOccupancyOnCompletion:complete];
}

@end

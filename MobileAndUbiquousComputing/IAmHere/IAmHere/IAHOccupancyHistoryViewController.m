//
//  IAHOccupancyHistoryViewController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHOccupancyHistoryViewController.h"
#import "IAHCommunicationController.h"

@interface IAHOccupancyHistoryViewController ()

@end

@implementation IAHOccupancyHistoryViewController

-(void)fetchOccupancy:(completionBlockWithResponseObject)complete
{
    IAHCommunicationController *controller = [IAHCommunicationController sharedController];
    [controller getOccupancyHistoryOnCompletion:complete];
}

@end

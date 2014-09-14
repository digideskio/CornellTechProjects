//
//  IAHOccupancyViewController.h
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^completionBlockWithResponseObject)(id responseObject);

@interface IAHOccupancyViewController : UIViewController

-(void)fetchOccupancy:(completionBlockWithResponseObject)complete;

@end

//
//  IAHRegionController.h
//  IAmHere
//
//  Created by James Kizer on 9/12/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "IAHLocation.h"


//#define METERS_PER_MILE 1609.344

typedef void (^completionBlockWithBool)(BOOL atCornellTech);
typedef void (^completionBlock)();

@interface IAHRegionController : NSObject

+ (id)sharedManager;
+ (IAHLocation *)cornellTechLocation;
+ (CLLocationDistance)cornellTechRegionRadius;

-(BOOL)atCornellTechOnCompletion:(completionBlockWithBool)complete;
- (BOOL)regionMonitoringEnabled;
- (void)setRegionMonitoring:(BOOL)enabled completion:(completionBlock)complete;

@end

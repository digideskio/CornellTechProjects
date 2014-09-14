//
//  IAHCommunicationController.h
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^completionBlockWithResponseObject)(id responseObject);

@interface IAHCommunicationController : NSObject

+ (id)sharedController;
@property (nonatomic) NSUInteger retryCount;

-(void)arrive;
-(void)update;
-(void)depart;

-(void)getOccupancyHistoryOnCompletion:(completionBlockWithResponseObject)complete;
-(void)getCurrentOccupancyOnCompletion:(completionBlockWithResponseObject)complete;

@end

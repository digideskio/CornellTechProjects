//
//  IAHCommunicationController.h
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAHOccupancyObject.h"
#import <AFNetworking.h>

typedef void (^completionBlockWithResponseObject)(id responseObject);
typedef void (^ReachabilityStatusChangeBlockType)(AFNetworkReachabilityStatus status);

@interface IAHCommunicationController : NSObject

+ (id)sharedController;
@property (nonatomic) NSUInteger retryCount;

//-(void)arrive;
//-(void)depart;

-(void)arriveWithName:(NSString *)name success:(completionBlockWithResponseObject)complete failure:(void (^)(UIBackgroundFetchResult))completionHandler;
-(void)updateForOccupancyObject:(IAHOccupancyObject*)occupancyObject success:(completionBlockWithResponseObject)complete failure:(void (^)(UIBackgroundFetchResult))completionHandler;
-(void)departForOccupancyObject:(IAHOccupancyObject*)occupancyObject success:(completionBlockWithResponseObject)complete failure:(void (^)(UIBackgroundFetchResult))completionHandler;

-(void)getOccupancyHistoryOnCompletion:(completionBlockWithResponseObject)complete;
-(void)getCurrentOccupancyOnCompletion:(completionBlockWithResponseObject)complete;

-(void)addReachabilityStatusChangeBlock:(ReachabilityStatusChangeBlockType)block;
-(BOOL)reachable;

@end

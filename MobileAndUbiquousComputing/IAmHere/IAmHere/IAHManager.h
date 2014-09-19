//
//  IAHManager.h
//  IAmHere
//
//  Created by James Kizer on 9/14/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^completionBlock)();

@interface IAHManager : NSObject

+ (id)sharedManager;

-(void)postArrive;
-(void)postDepart;

-(void)performBackgroundFetch:(void (^)(UIBackgroundFetchResult))completionHandler;

@property (strong, nonatomic) NSString *name;
-(void)setName:(NSString *)name completion:(completionBlock)complete;

@property (strong, nonatomic) NSString *statusUpdates;

-(void)IAHLog:(NSString *)logString;

-(void)disablePollTimer;
-(void)enablePollTimer;

@end

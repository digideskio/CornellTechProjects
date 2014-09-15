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

@property (strong, nonatomic) NSString *name;
-(void)setName:(NSString *)name completion:(completionBlock)complete;

@property (strong, nonatomic) NSString *statusUpdates;
@end

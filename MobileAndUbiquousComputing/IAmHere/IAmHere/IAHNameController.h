//
//  IAHNameController.h
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^completionBlock)();

@interface IAHNameController : NSObject

+ (id)sharedManager;

@property (strong, nonatomic) NSString *name;
-(void)setName:(NSString *)name completion:(completionBlock)complete;
@end

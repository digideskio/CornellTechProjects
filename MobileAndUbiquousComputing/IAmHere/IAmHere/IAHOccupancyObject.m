//
//  IAHOccupancyObject.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHOccupancyObject.h"

@implementation IAHOccupancyObject



- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self)
    {
        _name = [dictionary objectForKey:@"name"];
    }
    return self;
    
}

@end

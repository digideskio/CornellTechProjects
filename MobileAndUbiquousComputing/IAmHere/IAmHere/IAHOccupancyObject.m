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
        _idNumber = [NSNumber numberWithInteger:[[dictionary objectForKey:@"id"] integerValue]];
        _arrive = [[IAHOccupancyObject longDateFormatter] dateFromString:[dictionary objectForKey:@"arrive"]];
        _update = [[IAHOccupancyObject longDateFormatter] dateFromString:[dictionary objectForKey:@"update"]];
        if(![[dictionary objectForKey:@"depart"] isKindOfClass:[NSNull class]])
            _depart = [[IAHOccupancyObject longDateFormatter] dateFromString:[dictionary objectForKey:@"depart"]];
        if(![[dictionary objectForKey:@"floor"] isKindOfClass:[NSNull class]])
            _floor = [dictionary objectForKey:@"depart"];
        else
            _floor = @"";
        
    }
    return self;
    
}

+(NSDateFormatter *)longDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return dateFormatter;
}



@end

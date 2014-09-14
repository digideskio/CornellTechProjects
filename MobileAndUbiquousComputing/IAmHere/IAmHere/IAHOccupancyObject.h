//
//  IAHOccupancyObject.h
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAHOccupancyObject : NSObject

@property (strong, nonatomic) NSNumber *idNumber;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSDate *arrive;
@property (strong, nonatomic) NSDate *depart;
@property (strong, nonatomic) NSDate *update;
@property (strong, nonatomic) NSString *floor;

- (id)initWithDictionary:(NSDictionary *)dictionary;

+(NSDateFormatter *)longDateFormatter;

@end

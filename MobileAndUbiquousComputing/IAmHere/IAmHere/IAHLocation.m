//
//  IAHLocation.m
//  IAmHere
//
//  Created by James Kizer on 9/12/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHLocation.h"

@implementation IAHLocation

- (id)initWithTitle:(NSString *)title
           latitude:(CLLocationDegrees)latitude
          longitude:(CLLocationDegrees)longitude
{
    self = [super initWithLatitude:latitude longitude:longitude];
    if(self)
    {
        _title = title;
    }
    return self;
}


@end

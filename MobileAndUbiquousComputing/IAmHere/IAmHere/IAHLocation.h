//
//  IAHLocation.h
//  IAmHere
//
//  Created by James Kizer on 9/12/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface IAHLocation  : CLLocation <MKAnnotation>

- (id)initWithTitle:(NSString *)title
           latitude:(CLLocationDegrees)latitude
          longitude:(CLLocationDegrees)longitude;

@property (nonatomic, readonly, copy) NSString *title;

@end

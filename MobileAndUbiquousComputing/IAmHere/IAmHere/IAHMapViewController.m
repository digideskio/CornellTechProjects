//
//  IAHMapViewController.m
//  IAmHere
//
//  Created by James Kizer on 9/12/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHMapViewController.h"
#import <MapKit/MapKit.h>
#import "IAHRegionController.h"
#import <CoreLocation/CoreLocation.h>
#import "IAHLocation.h"

@interface IAHMapViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) IAHLocation *cornellTechLocation;
@property (strong, nonatomic) MKCircle *cornellTechCircle;

@end

@implementation IAHMapViewController

-(CLLocationManager *)locationManager
{
    if(!_locationManager) _locationManager = [[CLLocationManager alloc] init];
    return _locationManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.distanceFilter = 500;
    
    self.cornellTechLocation = [IAHRegionController cornellTechLocation];
    self.cornellTechCircle = [MKCircle circleWithCenterCoordinate:self.cornellTechLocation.coordinate radius:1000];
    
    //this defines coordinate, so should be fine
    //[self.mapView addAnnotation:self.cornellTechLocation];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.locationManager startUpdatingLocation];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.locationManager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.currentLocation = [locations lastObject];
    [self updateMapUI:NO];
}


-(void)updateMapUI:(BOOL)animated
{
    assert(self.cornellTechLocation);
    assert(self.currentLocation);
    [self.mapView showAnnotations:@[self.currentLocation, self.cornellTechLocation] animated:animated];
    [self.mapView removeAnnotation:(id<MKAnnotation>)self.currentLocation];
    [self.mapView addOverlay:self.cornellTechCircle level:MKOverlayLevelAboveRoads];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

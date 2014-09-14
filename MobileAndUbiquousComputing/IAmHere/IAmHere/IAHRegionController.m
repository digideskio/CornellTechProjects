//
//  IAHRegionController.m
//  IAmHere
//
//  Created by James Kizer on 9/12/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHRegionController.h"
#import "IAHOccupancyObject.h" 
#import "IAHCommunicationController.h"
#import "IAHNameController.h"

static CLLocationCoordinate2D CornellTechCoordinates = {40.7411873,-74.0026933};
static CLLocationDistance CornellTechRegionRadius = 100; //100m

//static NSTimeInterval updateDelayTime = 10*60; //20 mins
static NSTimeInterval updateDelayTime = 60; //10 sec

static NSTimeInterval clearDelayTime = 30*60;

typedef NS_ENUM(NSInteger, IAHRegionState) {
    IAHRegionStateInside,
    IAHRegionStateOutside
};

@interface IAHRegionController ()  <CLLocationManagerDelegate>


@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLCircularRegion *cornellTechRegion;
@property (nonatomic) IAHRegionState state;
@property (strong, atomic) completionBlockWithBool atCornellTechCompletionBlock;
@property (atomic) BOOL stateRequested;
@property (strong, nonatomic) IAHOccupancyObject *occupancyObject;

@end

@implementation IAHRegionController

+ (id)sharedManager {
    static IAHRegionController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

-(id)init{
    self = [super init];
    if (self) {
//        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(nameChanged) name:@"NameChanged" object:nil];
//        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(nameCleared) name:@"NameCleared" object:nil];
//        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(beginRegionMonitoring) name:@"BeginRegionMonitoring" object:nil];
//        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(endRegionMonitoring) name:@"EndRegionMonitoring" object:nil];
        
        //self.state = IAHRegionStateOutside;
        
        self.locationManager.delegate = self;
        self.cornellTechRegion = [[CLCircularRegion alloc]initWithCenter:CornellTechCoordinates radius:CornellTechRegionRadius identifier:@"Cornell Tech Geofence"];
        //only begin monitoring when a valid name is in place
        self.atCornellTechCompletionBlock = nil;

        //[self endRegionMonitoring:nil];
        
    }
    
    return self;
}

-(CLLocationManager *)locationManager
{
    if(!_locationManager) _locationManager = [[CLLocationManager alloc] init];
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Just entered %@", region.identifier);
    [self arriveHandler];
}

-(void)arriveHandler
{
    //assert(self.state == IAHRegionStateOutside);
    //self.state = IAHRegionStateInside;
    
    //tell comm controller to issue arrive
    NSLog(@"sending arrival message");
    
    [[IAHCommunicationController sharedController] arriveWithName:[[IAHNameController sharedManager] name]
                                                     onCompletion:^(id responseObject)
    {
        self.occupancyObject = [[IAHOccupancyObject alloc]initWithDictionary:(NSDictionary *)responseObject];
        //perform update in 20 mins
        [self performSelector:@selector(updateAlarmHandler) withObject:nil afterDelay:updateDelayTime];
        //[self performSelector:@selector(clearAlarmHandler) withObject:nil afterDelay:clearDelayTime];
    }];
    
    
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Just exited %@", region.identifier);
    [self departHandler];
}

-(void)departHandler
{
    //assert(self.state == IAHRegionStateInside);
    //self.state = IAHRegionStateOutside;
    if(self.occupancyObject)
    {
        
        //tell comm controller to issue depart
        NSLog(@"sending depart message");
        
        //cancel update
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAlarmHandler) object:nil];
        
        [[IAHCommunicationController sharedController] departForOccupancyObject:self.occupancyObject
                                                                   onCompletion:^(id responseObject)
         {
             //self.occupancyObject = [[IAHOccupancyObject alloc]initWithDictionary:(NSDictionary *)responseObject];
             //perform update in 20 mins
             //[self performSelector:@selector(updateAlarmHandler) withObject:nil afterDelay:updateDelayTime];
             //[self performSelector:@selector(clearAlarmHandler) withObject:nil afterDelay:clearDelayTime];
         }];
    }
}

- (void)updateAlarmHandler
{
    //assert(self.state == IAHRegionStateInside);
    assert(self.occupancyObject);
    //tell comm controller to issue update
    NSLog(@"sending update message");
    
    [[IAHCommunicationController sharedController] updateForOccupancyObject:self.occupancyObject
                                                               onCompletion:^(id responseObject)
     {
         //self.occupancyObject = [[IAHOccupancyObject alloc]initWithDictionary:(NSDictionary *)responseObject];
         //perform update in 20 mins
         [self performSelector:@selector(updateAlarmHandler) withObject:nil afterDelay:updateDelayTime];
         //[self performSelector:@selector(clearAlarmHandler) withObject:nil afterDelay:clearDelayTime];
     }];
}

//- (BOOL)atCornellTech
//{
//    return (self.state == IAHRegionStateInside);
//    
//    
//}

-(BOOL)locationManager:(CLLocationManager *)locationManager
    isMonitoringRegion:(CLRegion *)region
{
    NSSet *monitoredRegions = locationManager.monitoredRegions;
    
    __block BOOL found = NO;
   [monitoredRegions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
       CLRegion *thisRegion = (CLRegion *)obj;
       if([thisRegion.identifier isEqualToString:region.identifier])
           found = YES;
   }];
    return found;
}

- (BOOL)regionMonitoringEnabled;
{
    return [self locationManager:self.locationManager isMonitoringRegion:self.cornellTechRegion];
}

- (void)beginRegionMonitoring:(completionBlock)complete
{
    //assert(![self regionMonitoringEnabled]);
    NSLog(@"Beginning Region Monitoring");
    
    [self.locationManager startMonitoringForRegion:self.cornellTechRegion];
    //if we are at cornell tech, and we are starting region monitoring, must send arrive message
//    if([self atCornellTech])
//    {
//        [self arriveHandler];
//    }
    while([self atCornellTechOnCompletion:^(BOOL atCornellTech) {
        
        if (atCornellTech)
        {
            //NSLog(@"At Cornell Tech, sending arrival message");
            [self arriveHandler];
        }
        
        if(complete)
            complete();
        
    }] == NO);
    
    
    
}

-(BOOL)atCornellTechOnCompletion:(completionBlockWithBool)complete
{
    if(!self.atCornellTechCompletionBlock)
    {
        //NSLog(@"atCornellTechCompletionBlock nil, requesting state");
        self.atCornellTechCompletionBlock = complete;
        self.stateRequested = YES;
        [self.locationManager performSelector:@selector(requestStateForRegion:) withObject:self.cornellTechRegion afterDelay:1];
        return YES;
    }
    else
        return NO;
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    //NSLog(@"Determined State");
    if(self.stateRequested)
    {
        //NSLog(@"State Requested By Controller");
        if([region.identifier isEqualToString:self.cornellTechRegion.identifier])
        {
            if(state != CLRegionStateUnknown)
            {
                //NSLog(@"invoking atCornellTechCompletionBlock");
                self.atCornellTechCompletionBlock(state ==CLRegionStateInside);
                //NSLog(@"clearing atCornellTechCompletionBlock");
                self.atCornellTechCompletionBlock = nil;
                self.stateRequested = NO;
            }
            else
            {
                //NSLog(@"Error determining state");
                //retry
                [self.locationManager requestStateForRegion:self.cornellTechRegion];
            }
        }
    }
//    else
//        NSLog(@"State Requested By System");
}

- (void)endRegionMonitoring:(completionBlock)complete
{
    //assert([self regionMonitoringEnabled]);
    NSLog(@"Ending Region Monitoring");
    
    //if region monitoring is already disabled, ignore
    if(![self regionMonitoringEnabled])
    {
        //NSLog(@"Region Monitoring Disabled, ignoring checking to see if we are at Cornell Tech");
        if(complete)
            complete();
        return;
    }
    
    //if we are at cornell tech, and we are ending region monitoring, must send depart message
    while([self atCornellTechOnCompletion:^(BOOL atCornellTech) {
        
        if (atCornellTech)
        {
            //NSLog(@"At Cornell Tech, sending depart message");
            [self departHandler];
        }
        
        [self.locationManager stopMonitoringForRegion:self.cornellTechRegion];
        
        if(complete)
            complete();
        
    }] == NO);
}



-(void)setRegionMonitoring:(BOOL)enabled completion:(completionBlock)complete
{
    if([self regionMonitoringEnabled] != enabled)
    {
        if (enabled)
        {
            //NSLog(@"In setRegionMonitoring, beginning monitoring");
            [self beginRegionMonitoring:complete];
        }
        else
        {
            //NSLog(@"In setRegionMonitoring, ending monitoring");
            [self endRegionMonitoring:complete];
        }
    }
    else
    {
        //NSLog(@"In setRegionMonitoring, no need to change state. Calling Completion handler");
        if (complete)
            complete();
    }
}

//-(void)nameChanged
//{
//    if(![self regionMonitoringEnabled])
//    {
//        [self beginRegionMonitoring:nil];
//    }
//    else if(self.state == IAHRegionStateInside)
//    {
//        //depart
//        [self departHandler];
//        //arive
//        [self arriveHandler];
//    }
//}
//
//-(void)nameCleared
//{
//    assert([self locationManager:self.locationManager isMonitoringRegion:self.cornellTechRegion]);
//    
//    [self endRegionMonitoring];
//    if(self.state == IAHRegionStateInside)
//    {
//        //depart
//        [self departHandler];
//    }
//}

+ (IAHLocation *)cornellTechLocation
{
    
    IAHLocation *cornellTechLocation = [[IAHLocation alloc]initWithTitle:@"Cornell Tech" latitude:CornellTechCoordinates.latitude longitude:CornellTechCoordinates.longitude];
    
    return cornellTechLocation;
}

+ (CLLocationDistance)cornellTechRegionRadius
{
    return CornellTechRegionRadius;
}

@end

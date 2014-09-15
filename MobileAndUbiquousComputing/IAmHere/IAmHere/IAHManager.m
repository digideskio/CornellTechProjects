//
//  IAHManager.m
//  IAmHere
//
//  Created by James Kizer on 9/14/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHManager.h"
#import "IAHCommunicationController.h"
#import "IAHRegionController.h"
#import "IAHOccupancyObject.h"

static NSString *SavedNameNSUserDefaultsKey = @"SaveNameNSUserDefaultsKey";

//static NSTimeInterval updateDelayTime = 20*60; //20 mins
static NSTimeInterval updateDelayTime = 10; //10 sec
static NSTimeInterval resetDelayTime = 29*60 + 55;

typedef NS_ENUM(NSInteger, IAHManagerQueueState) {
    IAHManagerQueueEmpty,
    IAHManagerQueueArrive,
    IAHManagerQueueUpdate,
    IAHManagerQueueDepart
};

typedef NS_ENUM(NSInteger, IAHManagerRequest) {
    IAHManagerRequestArrive,
    IAHManagerRequestUpdate,
    IAHManagerRequestDepart
};

@interface IAHManager()

@property (strong, nonatomic) IAHOccupancyObject *occupancyObject;
@property (nonatomic) IAHManagerQueueState queueState;
//@property (strong, nonatomic) NSTimer *updateTimer;
//@property (strong, nonatomic) NSTimer *resetTimer;
@property (atomic) BOOL reachable;
@property (strong, nonatomic) NSDate *lastUpdate;
@property (nonatomic) BOOL shouldUpdateOnExpiration;
@property (nonatomic) BOOL shouldResetOnExpiration;

@end

@implementation IAHManager

+ (id)sharedManager {
    static IAHManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(id)init{
    self = [super init];
    if (self)
    {
        _name = [[NSUserDefaults standardUserDefaults] stringForKey:SavedNameNSUserDefaultsKey];
        _queueState = IAHManagerQueueEmpty;
        
        __weak IAHManager *weakSelf = self;
        ReachabilityStatusChangeBlockType queueBlock = ^(AFNetworkReachabilityStatus status) {
            
            if( (status == AFNetworkReachabilityStatusReachableViaWiFi) || (status == AFNetworkReachabilityStatusReachableViaWWAN))
            {
                self.reachable = YES;
                switch (weakSelf.queueState)
                {
                    case IAHManagerQueueArrive:
                        [self internalArrive];
                        break;
                        
                    case IAHManagerQueueDepart:
                        [self internalDepart];
                        break;
                        
                    case IAHManagerQueueUpdate:
                        [self internalUpdate];
                        break;
                        
                    case IAHManagerQueueEmpty:
                        break;
                    default:
                        assert(NO);
                        break;
                }
                weakSelf.queueState = IAHManagerQueueEmpty;
            }
            else
                self.reachable = NO;
            
        };
        
        [[IAHCommunicationController sharedController] addReachabilityStatusChangeBlock:queueBlock];
        
    }
    
    return self;
}

-(void)IAHLog:(NSString *)message
{
    self.statusUpdates = [self.statusUpdates stringByAppendingString:[NSString stringWithFormat:@"[%@]: %@\n", [NSDate date], message]];
}

-(NSString *)statusUpdates
{
    if(!_statusUpdates) _statusUpdates = [[NSString alloc]init];
    return _statusUpdates;
}

//-(void)setQueueState:(IAHManagerQueueState)queueState
//{
//    if(queueState == IAHManagerQueueDepart)
//    {
////        [self.resetTimer invalidate];
////        self.resetTimer = nil;
//        [self.updateTimer invalidate];
//        self.updateTimer = nil;
//    }
//    _queueState = queueState;
//}

//-(NSTimer *)newUpdateTimer
//{
//    return [NSTimer scheduledTimerWithTimeInterval:updateDelayTime target:self selector:@selector(updateAlarmHandler) userInfo:nil repeats:NO];
//}
//
//-(NSTimer *)newResetTimer
//{
//    return [NSTimer scheduledTimerWithTimeInterval:resetDelayTime target:self selector:@selector(resetAlarmHandler) userInfo:nil repeats:NO];
//}


//implement the queue FSM
-(void)updateQueueWithRequest:(IAHManagerRequest)request
{
    switch (self.queueState)
    {
        case IAHManagerQueueArrive:
            switch(request)
        {
                
            case IAHManagerRequestDepart:
                self.queueState = IAHManagerQueueEmpty;
                break;
                
            case IAHManagerRequestArrive:
            case IAHManagerRequestUpdate:
            default:
                assert(NO);
                break;
        }
            
            
            break;
            
        case IAHManagerQueueDepart:
            switch(request)
        {
                
            case IAHManagerRequestDepart:
                self.queueState = IAHManagerQueueEmpty;
                break;
                
            case IAHManagerRequestArrive:
            case IAHManagerRequestUpdate:
            default:
                assert(NO);
                break;
        }
            
            break;
            
        case IAHManagerQueueUpdate:
            switch(request)
        {
                
            case IAHManagerRequestDepart:
                self.queueState = IAHManagerQueueDepart;
                break;
                
            case IAHManagerRequestArrive:
            case IAHManagerRequestUpdate:
            default:
                assert(NO);
                break;
        }
            break;
            
        case IAHManagerQueueEmpty:
            switch(request)
        {
            case IAHManagerRequestArrive:
                self.queueState = IAHManagerQueueArrive;
                break;
                
            case IAHManagerRequestDepart:
                self.queueState = IAHManagerQueueDepart;
                break;
                
            case IAHManagerRequestUpdate:
                self.queueState = IAHManagerQueueUpdate;
                break;
                
            default:
                assert(NO);
                break;
        }
            
            break;
            
        default:
            assert(NO);
            break;
    }
}

-(void)postArrive
{
    [self IAHLog:@"Posting Arrive"];
    assert(!self.occupancyObject);
    if(self.reachable)
    {
        [self internalArrive];
    }
    else
        [self updateQueueWithRequest:IAHManagerRequestArrive];
    
}

-(void)internalArrive
{
//    assert(!self.updateTimer);
//    assert(!self.resetTimer);
    assert(!self.occupancyObject);
    [[IAHCommunicationController sharedController] arriveWithName:self.name onCompletion:^(id responseObject) {
        
        assert(responseObject);
        self.occupancyObject = [[IAHOccupancyObject alloc] initWithDictionary:(NSDictionary *)responseObject];
        
        //set update and reset timers
        //[self setUpdateAndResetTimers];
        
        self.lastUpdate = [NSDate date];
        self.shouldUpdateOnExpiration = YES;
        self.shouldResetOnExpiration = YES;
        
    }];
    
    
}

-(void)setUpdateAndResetTimers
{
//    assert(!self.updateTimer);
//    assert(!self.resetTimer);
    //self.updateTimer = [self newUpdateTimer];
    //self.resetTimer = [self newResetTimer];
    [self performSelector:@selector(updateAlarmHandler) withObject:nil afterDelay:updateDelayTime];
    [self performSelector:@selector(resetAlarmHandler) withObject:nil afterDelay:resetDelayTime];
    
}

-(void)postDepart
{
    [self IAHLog:@"Posting Depart"];
    //workaround for phantom departures
    if(!self.occupancyObject)
        return;
    
//    assert([self.updateTimer isValid]);
//    
//    [self.updateTimer invalidate];
//    self.updateTimer = nil;
    
    
    
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAlarmHandler) object:nil];
    
    if(self.reachable)
    {
        [self internalDepart];
    }
    else
        [self updateQueueWithRequest:IAHManagerRequestDepart];
}

-(void)internalDepart
{
//    assert(!self.updateTimer);
//    assert([self.resetTimer isValid]);
//    [self.resetTimer invalidate];
//    self.resetTimer = nil;
    
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetAlarmHandler) object:nil];
    
    assert(self.occupancyObject);
    [[IAHCommunicationController sharedController] departForOccupancyObject:self.occupancyObject onCompletion:^(id responseObject) {
        
        assert(responseObject);
        
        //clear occupancy object
        self.occupancyObject = nil;
        self.lastUpdate = nil;
        
    }];
    
}

-(void)update
{
    
    if(self.reachable)
    {
        [self internalUpdate];
    }
    else
        [self updateQueueWithRequest:IAHManagerRequestUpdate];
}

-(void)internalUpdate
{
//    assert([self.resetTimer isValid]);
//    [self.resetTimer invalidate];
//    self.resetTimer = nil;
    
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetAlarmHandler) object:nil];
    
//    assert(!self.updateTimer);
//    assert(!self.resetTimer);
    assert(self.occupancyObject);
    
    [[IAHCommunicationController sharedController] updateForOccupancyObject:self.occupancyObject onCompletion:^(id responseObject) {
        
        assert(responseObject);
        
        //set update and reset timers
        //[self setUpdateAndResetTimers];
        self.lastUpdate = [NSDate date];
        self.shouldUpdateOnExpiration = YES;
        
    }];
}

-(void)performBackgroundFetch:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self IAHLog:@"Background Fetch"];
    NSLog(@"Background Fetch");
    
//    if(self.shouldResetOnExpiration && [[self.lastUpdate dateByAddingTimeInterval:resetDelayTime] timeIntervalSinceNow] < 0)
//    {
//
//    }
    
    //check for reset
//    if( !self.resetIssued && [[self.lastUpdate dateByAddingTimeInterval:resetDelayTime] timeIntervalSinceNow] < 0)
//    {
//        [self IAHLog:@"Background Fetch"];
//        NSLog(@"Background Fetch");
//        [self resetAlarmHandler];
//    }
//    else if( !self.updateIssued && ([[self.lastUpdate dateByAddingTimeInterval:updateDelayTime] timeIntervalSinceNow] < 0))
//    {
//        [self IAHLog:@"Background Fetch"];
//        NSLog(@"Background Fetch");
//        //[self updateAlarmHandler];
//        
//        {
//            //    assert([self.resetTimer isValid]);
//            //    [self.resetTimer invalidate];
//            //    self.resetTimer = nil;
//            
//            //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetAlarmHandler) object:nil];
//            
//            //    assert(!self.updateTimer);
//            //    assert(!self.resetTimer);
//            assert(self.occupancyObject);
//            
//            [[IAHCommunicationController sharedController] updateForOccupancyObject:self.occupancyObject onCompletion:^(id responseObject) {
//                
//                assert(responseObject);
//                
//                //set update and reset timers
//                //[self setUpdateAndResetTimers];
//                self.lastUpdate = [NSDate date];
//                self.updateIssued = NO;
//                
//                if(completionHandler)
//                    completionHandler(UIBackgroundFetchResultNoData);
//                
//            }];
//        }
//    }
    
    if(completionHandler)
        completionHandler(UIBackgroundFetchResultNoData);
}

-(void)updateAlarmHandler
{
    [self IAHLog:@"Update alarm handler"];
    self.shouldUpdateOnExpiration = NO;
//    assert(self.updateTimer);
//    [self.updateTimer invalidate];
//    self.updateTimer = nil;
    
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAlarmHandler) object:nil];
    
    [self update];
}

-(void)resetAlarmHandler
{
    [self IAHLog:@"Reset alarm handler"];
    self.shouldUpdateOnExpiration = NO;
    self.shouldResetOnExpiration = NO;
//    assert(self.resetTimer);
//    [self.resetTimer invalidate];
//    self.resetTimer = nil;
    
    
    
    
    switch (self.queueState)
    {
        case IAHManagerQueueDepart:
            assert(self.occupancyObject);
            self.queueState = IAHManagerQueueEmpty;
            self.occupancyObject = nil;
            break;
            
        case IAHManagerQueueUpdate:
            assert(self.occupancyObject);
            self.queueState = IAHManagerQueueArrive;
            self.occupancyObject = nil;
            break;
            
        case IAHManagerQueueArrive:
        case IAHManagerQueueEmpty:
        default:
            assert(NO);
            break;
    }
}

-(NSString *)name
{
    if(!_name) _name = @"";
    return _name;
}

-(void)setName:(NSString *)name completion:(completionBlock)complete
{
    
    //disable monitoring
    
    IAHRegionController *regionController = [IAHRegionController sharedManager];
    __weak IAHRegionController *weakRegionController = regionController;
    
    BOOL regionMonitoringState;
    
    if([_name isEqualToString:@""])
        regionMonitoringState = YES;
    else
        regionMonitoringState = [regionController regionMonitoringEnabled];
    
    [regionController setRegionMonitoring:NO completion:^{
        assert(name);
        _name = name;
        
        [[NSUserDefaults standardUserDefaults] setObject:name forKey:SavedNameNSUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if([name length] > 0)
        {
            if(regionMonitoringState)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakRegionController setRegionMonitoring:YES completion:^{
                        if(complete)
                            complete();
                    }];
                });
            
            else
                if(complete)
                    complete();
        }
        else
        {
            if(complete)
                complete();
        }
    }];
    
}

@end

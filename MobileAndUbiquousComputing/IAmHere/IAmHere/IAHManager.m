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
static NSTimeInterval pollingPeriod = 5*60;
static NSTimeInterval updateDelayTime = 10*60; //10 sec
//static NSTimeInterval resetDelayTime = 30; //10 sec
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
@property (atomic) BOOL reachable;


@property (strong, nonatomic) NSTimer *pollTimer;
@property (strong, nonatomic) NSDate *nextPollTimerFireTime;

@property (strong, nonatomic) NSDate *nextUpdate;
@property (nonatomic) BOOL shouldUpdateOnExpiration;

@property (strong, nonatomic) NSDate *nextReset;
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
        
        [self enablePollTimer];
        
        __weak IAHManager *weakSelf = self;
        self.reachable = NO;
        ReachabilityStatusChangeBlockType queueBlock = ^(AFNetworkReachabilityStatus status) {
            
            if( (status == AFNetworkReachabilityStatusReachableViaWiFi) || (status == AFNetworkReachabilityStatusReachableViaWWAN))
            {
                weakSelf.reachable = YES;
                [weakSelf IAHLog:@"Network has become reachable"];
                [weakSelf performQueuedOperation:nil];
            }
            else
            {
                [weakSelf IAHLog:@"Network has become unreachable"];
                weakSelf.reachable = NO;
            }
            
        };
        
        [[IAHCommunicationController sharedController] addReachabilityStatusChangeBlock:queueBlock];
        
        //check to see if we are on campus when we initialize
        //if so, post arrival notice
        while ([[IAHRegionController sharedManager] atCornellTechOnCompletion:^(BOOL atCornellTech) {
            if(atCornellTech)
                [self postArrive];
        }] == NO);
        
    }
    
    return self;
}

-(void)disablePollTimer
{
    self.nextPollTimerFireTime = [self.pollTimer fireDate];
    [self.pollTimer invalidate];
}

-(void)enablePollTimer
{
    if(!self.nextPollTimerFireTime || ([self.nextPollTimerFireTime timeIntervalSinceNow] < 0))
        self.nextPollTimerFireTime = [NSDate dateWithTimeIntervalSinceNow:pollingPeriod];
    
    [self IAHLog:[NSString stringWithFormat:@"Setting poll timer fire time to %@", self.nextPollTimerFireTime]];
    self.pollTimer = [[NSTimer alloc] initWithFireDate:self.nextPollTimerFireTime interval:pollingPeriod target:self selector:@selector(pollHandler:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.pollTimer forMode:NSDefaultRunLoopMode];
}

-(void)performQueuedOperation:(void (^)(UIBackgroundFetchResult))completionHandler
{
    IAHManagerQueueState state = self.queueState;
    self.queueState = IAHManagerQueueEmpty;
    switch (state)
    {
        case IAHManagerQueueArrive:
            [self internalArrive:completionHandler];
            break;
            
        case IAHManagerQueueDepart:
            [self internalDepart:completionHandler];
            break;
            
        case IAHManagerQueueUpdate:
            [self internalUpdate:completionHandler];
            break;
            
        case IAHManagerQueueEmpty:
            
            if(completionHandler)
                completionHandler(UIBackgroundFetchResultNoData);
            
            break;
        default:
            assert(NO);
            break;
    }
}

-(void)IAHLog:(NSString *)message
{
    NSLog(@"%@", message);
    self.statusUpdates = [self.statusUpdates stringByAppendingString:[NSString stringWithFormat:@"[%@]: %@\n", [NSDate date], message]];
}

-(NSString *)statusUpdates
{
    if(!_statusUpdates) _statusUpdates = [[NSString alloc]init];
    return _statusUpdates;
}

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

-(void)updateQueueForReset
{
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

-(void)postArrive
{
    [self IAHLog:@"Posting Arrive"];
    assert(!self.occupancyObject);
    if(self.reachable)
    {
        [self internalArrive:nil];
    }
    else
        [self updateQueueWithRequest:IAHManagerRequestArrive];
    
}

-(void)internalArrive:(void (^)(UIBackgroundFetchResult))completionHandler
{
    assert(!self.occupancyObject);
    [[IAHCommunicationController sharedController] arriveWithName:self.name success:^(id responseObject) {
        
        assert(responseObject);
        self.occupancyObject = [[IAHOccupancyObject alloc] initWithDictionary:(NSDictionary *)responseObject];
        
        [self setUpdateAndResetTimes];
        
        if(completionHandler)
            completionHandler(UIBackgroundFetchResultNewData);
        
    } failure:completionHandler];
    
    
}

-(void)setUpdateAndResetTimes
{
    self.nextUpdate = [NSDate dateWithTimeIntervalSinceNow:updateDelayTime];
    self.shouldUpdateOnExpiration = YES;
    [self IAHLog:[NSString stringWithFormat:@"Setting update time to %@", self.nextUpdate]];
    
    self.nextReset = [NSDate dateWithTimeIntervalSinceNow:resetDelayTime];
    self.shouldResetOnExpiration = YES;
    [self IAHLog:[NSString stringWithFormat:@"Setting reset time to %@", self.nextReset]];
}

-(void)clearUpdateAndResetTimes
{
    self.nextUpdate = [NSDate distantFuture];
    self.shouldUpdateOnExpiration = NO;
    
    self.nextReset = [NSDate distantFuture];
    self.shouldResetOnExpiration = NO;
}

-(void)postDepart
{
    [self IAHLog:@"Posting Depart"];
    //workaround for phantom departures
    if(self.queueState == IAHManagerQueueArrive || self.queueState == IAHManagerQueueUpdate)
        self.queueState = IAHManagerQueueEmpty;
    if(!self.occupancyObject)
    {
//        if(self.queueState == IAHManagerQueueArrive || self.queueState == IAHManagerQueueUpdate)
//            self.queueState = IAHManagerQueueEmpty;
        return;
    }
    
    
    self.nextUpdate = [NSDate distantFuture];
    self.shouldUpdateOnExpiration = NO;

    if(self.reachable)
    {
        [self internalDepart:nil];
    }
    else
        [self updateQueueWithRequest:IAHManagerRequestDepart];
}

-(void)internalDepart:(void (^)(UIBackgroundFetchResult))completionHandler
{

    self.nextUpdate = [NSDate distantFuture];
    self.shouldUpdateOnExpiration = NO;
    
    assert(self.occupancyObject);
    [[IAHCommunicationController sharedController] departForOccupancyObject:self.occupancyObject success:^(id responseObject) {
        
        assert(responseObject);
        
        //clear occupancy object
        self.occupancyObject = nil;
        
        self.nextReset = [NSDate distantFuture];
        self.shouldResetOnExpiration = NO;
        
        if(completionHandler)
            completionHandler(UIBackgroundFetchResultNewData);
        
    } failure:completionHandler];
    
}

-(void)update:(void (^)(UIBackgroundFetchResult))completionHandler
{
    
    if(self.reachable)
    {
        [self IAHLog:@"Invoking Update"];
        [self internalUpdate:completionHandler];
    }
    else
    {
        [self IAHLog:@"Adding Update to Queue"];
        [self updateQueueWithRequest:IAHManagerRequestUpdate];
        if(completionHandler)
            completionHandler(UIBackgroundFetchResultNoData);
    }
}

-(void)internalUpdate:(void (^)(UIBackgroundFetchResult))completionHandler
{

    
    self.nextUpdate = [NSDate distantFuture];
    self.shouldUpdateOnExpiration = NO;
    
    assert(self.occupancyObject);
    
    [[IAHCommunicationController sharedController] updateForOccupancyObject:self.occupancyObject success:^(id responseObject) {
        
        assert(responseObject);
        
        [self setUpdateAndResetTimes];
        
        if(completionHandler)
            completionHandler(UIBackgroundFetchResultNewData);
        
    } failure:completionHandler];
}

-(void)pollHandler:(NSTimer *)timer
{
    [self performBackgroundFetch:nil];
}

-(void)performBackgroundFetch:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if(completionHandler)
        [self IAHLog:@"Background Fetch"];
    else
        [self IAHLog:@"Foreground Alarm"];
    //NSLog(@"Background Fetch");
    
    //should I perform update or reset first??
    
    //if reset has expired, this means that someone was logged in, but they have now been logged out by the server
    //Therefore, we should not perform an update call in either case.
    
    //if we are resetting, allow the update to be added to the queue, then process the reset, then process the queue (if reachable)
    
    BOOL updating = NO;
    BOOL resetting = NO;
    
    if(self.shouldUpdateOnExpiration && [self.nextUpdate timeIntervalSinceNow] < 0)
    {
        [self IAHLog:@"Should Update"];
        self.shouldUpdateOnExpiration = NO;
        updating = YES;
    }
    
    if(self.shouldResetOnExpiration && [self.nextReset timeIntervalSinceNow] < 0)
    {
        [self IAHLog:@"Should Reset"];
        self.shouldResetOnExpiration = NO;
        resetting = YES;
    }
    
    
    //this is where the action happens
    if(resetting)
    {
        [self IAHLog:@"Resetting"];
        if(updating)
            [self updateQueueWithRequest:IAHManagerRequestUpdate];
        
        [self updateQueueForReset];
        
        if(self.reachable)
        {
            [self performQueuedOperation:completionHandler];
        }
        else
        {
            if(completionHandler)
                completionHandler(UIBackgroundFetchResultNoData);
        }
    }
    else if(updating)
    {
        [self IAHLog:@"Updating"];
        [self update:completionHandler];
    }
    
    else if(self.reachable)
    {
        [self IAHLog:@"Performing Queued Operation"];
        [self performQueuedOperation:completionHandler];
    }
    
    else
        if(completionHandler)
            completionHandler(UIBackgroundFetchResultNoData);
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

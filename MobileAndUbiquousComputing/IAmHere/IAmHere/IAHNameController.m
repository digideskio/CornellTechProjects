//
//  IAHNameController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHNameController.h"
#import "IAHRegionController.h"

static NSString *SavedNameNSUserDefaultsKey = @"SaveNameNSUserDefaultsKey";


@implementation IAHNameController


@synthesize name = _name;

+ (id)sharedManager {
    static IAHNameController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

-(id)init{
    self = [super init];
    if (self)
    {
        _name = [[NSUserDefaults standardUserDefaults] stringForKey:SavedNameNSUserDefaultsKey];
    }
    
    return self;
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
                    [regionController setRegionMonitoring:YES completion:^{
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

//
//  IAHCommunicationController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHCommunicationController.h"
#import "AFNetworking.h"

static NSString *baseURLString = @"http://iamhere.smalldata.io";
static NSUInteger defaultRetryCount = 3;


typedef NS_ENUM(NSInteger, IAHCommunicationControllerQueueState) {
    IAHCommunicationControllerQueueEmpty,
    IAHCommunicationControllerQueueArrive,
    IAHCommunicationControllerQueueUpdate,
    IAHCommunicationControllerQueueDepart
};

@interface IAHCommunicationController()

@property (strong, nonatomic) AFHTTPRequestOperationManager *operationManager;
@property (atomic) IAHCommunicationControllerQueueState queueState;

@end

@implementation IAHCommunicationController

+ (id)sharedController {
    static IAHCommunicationController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

-(id)init{
    self = [super init];
    if (self) {
        
        self.operationManager = [[AFHTTPRequestOperationManager alloc]initWithBaseURL:[NSURL URLWithString:baseURLString]];
        
        self.retryCount = defaultRetryCount;
        
        [self.operationManager.reachabilityManager startMonitoring];
        
        self.operationManager.responseSerializer.acceptableContentTypes = [self.operationManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        
        __weak IAHCommunicationController *weakSelf = self;
        [self.operationManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            
            if( (status == AFNetworkReachabilityStatusReachableViaWiFi) || (status == AFNetworkReachabilityStatusReachableViaWWAN))
            {
                switch (weakSelf.queueState)
                {
                    case IAHCommunicationControllerQueueArrive:
                        
                        break;
                        
                    case IAHCommunicationControllerQueueDepart:
                        
                        break;
                        
                    case IAHCommunicationControllerQueueUpdate:
                        
                        break;
                        
                    case IAHCommunicationControllerQueueEmpty:
                    default:
                        break;
                }
            }
            
        }];
        
    }
    
    return self;
}


-(void)getOccupancyHistoryOnCompletion:(completionBlockWithResponseObject)complete
{
    __block void (^requestBlock)(int);
    requestBlock = ^(int retryCount) {
        
        [self.operationManager GET:@"/history" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Got History Objects");
            if(complete)
                complete(responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (retryCount > 0)
            {
                NSLog(@"Retrying...");
                requestBlock(retryCount-1);
            }
            else
            {
                if(complete)
                    complete(nil);
            }
            
        }];
        
    };
    requestBlock(self.retryCount);
}

-(void)getCurrentOccupancyOnCompletion:(completionBlockWithResponseObject)complete
{
    __block void (^requestBlock)(int);
    requestBlock = ^(int retryCount) {
        
        [self.operationManager GET:@"/occupancy" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Got History Objects");
            if(complete)
                complete(responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (retryCount > 0)
            {
                NSLog(@"Retrying...");
                requestBlock(retryCount-1);
            }
            else
            {
                if(complete)
                    complete(nil);
            }
            
        }];
        
    };
    requestBlock(self.retryCount);
}



@end

//
//  IAHCommunicationController.m
//  IAmHere
//
//  Created by James Kizer on 9/13/14.
//  Copyright (c) 2014 Kizer Development. All rights reserved.
//

#import "IAHCommunicationController.h"
#import <AFNetworking.h>
#import "IAHNameController.h"
#import "IAHOccupancyObject.h"

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
@property (strong, nonatomic) IAHOccupancyObject *occupancyObject;
@property (strong, nonatomic) NSArray *reachabilityBlocks;

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

-(NSArray *)reachabilityBlocks
{
    if(!_reachabilityBlocks) _reachabilityBlocks = [[NSArray alloc]init];
    return _reachabilityBlocks;
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
            
            [weakSelf.reachabilityBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                ReachabilityStatusChangeBlockType block = (ReachabilityStatusChangeBlockType)obj;
                block(status);
            }];
            
        }];
        
        ReachabilityStatusChangeBlockType queueBlock = ^(AFNetworkReachabilityStatus status) {
            
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
            
        };
        
        [self addReachabilityStatusChangeBlock:queueBlock];
        
    }
    
    return self;
}

-(BOOL)reachable
{
    return self.operationManager.reachabilityManager.reachable;
}

-(void)addReachabilityStatusChangeBlock:(ReachabilityStatusChangeBlockType)block
{
    self.reachabilityBlocks = [self.reachabilityBlocks arrayByAddingObject:block];
}

-(void)arriveWithName:(NSString *)name onCompletion:(completionBlockWithResponseObject)complete
{
    if(self.operationManager.reachabilityManager.reachable)
    {
        NSString *name = [[IAHNameController sharedManager] name];
        [self postArrivalForName:name onCompletion:complete];
    }
    else
    {
        //self.queueState = IAHCommunicationControllerQueueArrive;
    }
}

-(void)postArrivalForName:(NSString *)name onCompletion:(completionBlockWithResponseObject)complete
{
    __block void (^requestBlock)(NSUInteger);
    __block void (^requestBlock2)(NSUInteger);
    requestBlock = ^(NSUInteger retryCount) {
        
        [self.operationManager POST:@"/occupancy" parameters:@{@"name" : name} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(complete)
                complete(responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (retryCount > 0)
            {
                NSLog(@"Retrying...");
                requestBlock2(retryCount-1);
            }
            else
            {
                if(complete)
                    complete(nil);
            }
            
        }];
        
    };
    requestBlock2 = requestBlock;
    requestBlock(self.retryCount);
}


-(void)updateForOccupancyObject:(IAHOccupancyObject*)occupancyObject onCompletion:(completionBlockWithResponseObject)complete
{
    if(self.operationManager.reachabilityManager.reachable)
    {
        [self postUpdateForOccupancyObject:occupancyObject onCompletion:complete];
    }
    else
    {
        //self.queueState = IAHCommunicationControllerQueueArrive;
    }
}

-(void)postUpdateForOccupancyObject:(IAHOccupancyObject *)occupancyObject onCompletion:(completionBlockWithResponseObject)complete
{
    __block void (^requestBlock)(NSUInteger);
    __block void (^requestBlock2)(NSUInteger);
    
    NSString *urlString = [NSString stringWithFormat:@"/occupancy/%@/update", occupancyObject.idNumber];
    
    requestBlock = ^(NSUInteger retryCount) {
        
        [self.operationManager POST:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(complete)
                complete(responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (retryCount > 0)
            {
                NSLog(@"Retrying...");
                requestBlock2(retryCount-1);
            }
            else
            {
                if(complete)
                    complete(nil);
            }
            
        }];
        
    };
    requestBlock2 = requestBlock;
    requestBlock(self.retryCount);
}

-(void)departForOccupancyObject:(IAHOccupancyObject*)occupancyObject onCompletion:(completionBlockWithResponseObject)complete
{
    if(self.operationManager.reachabilityManager.reachable)
    {
        [self postDepartForOccupancyObject:occupancyObject onCompletion:complete];
    }
    else
    {
        //self.queueState = IAHCommunicationControllerQueueArrive;
    }
}

-(void)postDepartForOccupancyObject:(IAHOccupancyObject *)occupancyObject onCompletion:(completionBlockWithResponseObject)complete
{
    __block void (^requestBlock)(NSUInteger);
    __block void (^requestBlock2)(NSUInteger);
    
    NSString *urlString = [NSString stringWithFormat:@"/occupancy/%@/depart", occupancyObject.idNumber];
    
    requestBlock = ^(NSUInteger retryCount) {
        
        NSMutableURLRequest *request = [self.operationManager.requestSerializer requestWithMethod:@"POST" URLString:[[NSURL URLWithString:urlString relativeToURL:self.operationManager.baseURL] absoluteString] parameters:nil error:nil];
        AFHTTPRequestOperation *operation = [self.operationManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(complete)
                complete(responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (retryCount > 0)
            {
                NSLog(@"Retrying...");
                requestBlock2(retryCount-1);
            }
            else
            {
                if(complete)
                    complete(nil);
            }
            
        }];
        
        operation.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [self.operationManager.operationQueue addOperation:operation];
    };
    requestBlock2 = requestBlock;
    requestBlock(self.retryCount);
}

-(void)getOccupancyHistoryOnCompletion:(completionBlockWithResponseObject)complete
{
    __block void (^requestBlock)(NSUInteger);
    __block void (^requestBlock2)(NSUInteger);
    requestBlock = ^(NSUInteger retryCount) {
        
        [self.operationManager GET:@"/history" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Got History Objects");
            if(complete)
                complete(responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (retryCount > 0)
            {
                NSLog(@"Retrying...");
                requestBlock2(retryCount-1);
            }
            else
            {
                if(complete)
                    complete(nil);
            }
            
        }];
        
    };
    requestBlock2 = requestBlock;
    requestBlock(self.retryCount);
}

-(void)getCurrentOccupancyOnCompletion:(completionBlockWithResponseObject)complete
{
    __block void (^requestBlock)(NSUInteger);
    __block void (^requestBlock2)(NSUInteger);
    requestBlock = ^(NSUInteger retryCount) {
        
        [self.operationManager GET:@"/occupancy" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Got History Objects");
            if(complete)
                complete(responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            if (retryCount > 0)
            {
                NSLog(@"Retrying...");
                requestBlock2(retryCount-1);
            }
            else
            {
                if(complete)
                    complete(nil);
            }
            
        }];
        
    };
    requestBlock2 = requestBlock;
    requestBlock(self.retryCount);
}



@end

//
//  Server.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Server.h"

#import <netdb.h>

#import "Exceptions.h"
#import "NetworkManager.h"
#import "NetworkWrapper.h"
#import "IONetworkHandler.h"
#import "DescriptorControlWrapper.h"

@interface Server()
{
    Identity * identity;
    NSThread * thread;
    NSLock * resourceLock;
    dispatch_queue_t notificationQueue;
    NSMutableArray<Connection*>* connections;
    NSObject<NetworkManageable>* networkManager;
}
@end

@implementation Server
@synthesize delegate=_delegate;
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration {
    return [self initWithConfiguratoin:configuration notificationQueue:dispatch_get_main_queue()];
}
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue {
    return [self initWithConfiguratoin:configuration
                     notificationQueue:notificationQueue
                        networkManager:[NetworkManager new]];
}
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager {
    self = [super init];
    if (self) {
        NSAssert([networkManager hasPortValidRange: configuration.port],
                 @"Port number should be within the range");
        self->identity = nil;
        self->thread = nil;
        self->resourceLock = [NSLock new];
        self->networkManager = networkManager;
        self->connections = [NSMutableArray new];
        self->notificationQueue = notificationQueue;
        self->_delegate = nil;
        self->_configuration = configuration;
    }
    return self;
}
-(void)boot {
    [resourceLock lock];
    if([thread isExecuting] && ![thread isCancelled]) {
        [resourceLock unlock];
        return;
    }
    if (identity == nil || ![networkManager isValidAndHealthy:identity]) {
        @try {
            identity = [networkManager localIdentityOnPort: _configuration.port maximalConnectionsCount:_configuration.maximalConnectionsCount];
        } @catch (IdentityCreationException * exception) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:exception.reason
                                              userInfo:nil];
        }
    }
    thread = [[NSThread alloc] initWithTarget:self
                                     selector:@selector(serve)
                                       object:nil];
    thread.name = @"ServerThread";
    [thread start];
    [resourceLock unlock];
}
-(void)serve {
    while(YES) {
        [resourceLock lock];
        if(!thread.cancelled) {
            NSMutableArray<Connection*>* connectionsToRemove = [NSMutableArray new];
            // perform IO
            for (ssize_t i=0; i<[connections count]; ++i) {
                Connection * connection = [connections objectAtIndex:i];
                if ([connection lastInteractionInterval] > self.configuration.connectionTimeout || [connection state] == closed) {
                    [connectionsToRemove addObject:connection];
                } else {
                    [connection performIO];
                }
            }
            // remove timed out or not open connections
            for (Connection * connection in connectionsToRemove) {
                [connection close];
                [connections removeObject:connection];
            }
            // accept new connections if amount of clients do not exceeds max
            if (self.configuration.maximalConnectionsCount > [connections count] && _delegate != nil) {
                Identity * newClientIdentity = [networkManager acceptNewIdentity:identity];
                if (newClientIdentity) {
                    Connection * connection = [[Connection alloc] initWithIdentity: newClientIdentity
                                                                         chunkSize:self.configuration.chunkSize
                                                                 notificationQueue: notificationQueue
                                                                    networkManager:networkManager];
                    __weak Server * weakSelf = self;
                    dispatch_async(notificationQueue, ^{
                        [weakSelf.delegate newClientHasConnected:connection];
                    });
                    [connections addObject:connection];
                }
            }
        } else {
            [resourceLock unlock];
            break;
        }
        [resourceLock unlock];
        usleep(self.configuration.eventLoopMicrosecondsDelay);
    }
    [resourceLock lock];
    for (Connection * connection in connections) {
        [connection close];
    }
    [resourceLock unlock];
}
-(void)shutDown {
    [resourceLock lock];
    [thread cancel];
    // wait for server to shutdown
    while([thread isExecuting]) {
        [resourceLock unlock];
        usleep(self.configuration.eventLoopMicrosecondsDelay);
        [resourceLock lock];
    }
    [connections removeAllObjects];
    if (![networkManager close:identity]) {
        [resourceLock unlock];
        @throw [ShuttingDownException exceptionWithName:@"ShuttingDownException"
                                                 reason:@"Could close server's socket" userInfo:nil];
    }
    [resourceLock unlock];
}
-(NSInteger)connectedClientsCount {
    [resourceLock lock];
    NSInteger count = [connections count];
    [resourceLock unlock];
    return count;
}
-(BOOL)isRunning {
    [resourceLock lock];
    BOOL running = thread && thread.isExecuting;
    [resourceLock unlock];
    return running;
}
@end

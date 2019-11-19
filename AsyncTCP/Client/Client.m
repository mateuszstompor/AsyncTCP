//
//  Client.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Client.h"
#import "Connection.h"
#import "Exceptions.h"
#import "ResourceLock.h"
#import "NetworkWrapper.h"
#import "NetworkManager.h"
#import "IONetworkHandler.h"
#import "SocketOptionsWrapper.h"
#import "DescriptorControlWrapper.h"

#include <arpa/inet.h>

@interface Client()
{
    NSThread * thread;
    Identity* identity;
    Connection * connection;
    NSObject<Lockable> * resourceLock;
    dispatch_queue_t notificationQueue;
    NSObject<NetworkManageable>* networkManager;
}
@end

@implementation Client
-(instancetype)initWithConfiguration:(struct ClientConfiguration)configuration {
    return [self initWithConfiguration:configuration notificationQueue:dispatch_get_main_queue()];
}
-(instancetype)initWithConfiguration:(struct ClientConfiguration)configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue {
    return [self initWithConfiguration:configuration
                     notificationQueue:notificationQueue
                        networkManager:[NetworkManager new]
                          resourceLock:[ResourceLock new]];
}
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager
                        resourceLock: (NSObject<Lockable>*) resourceLock {
    self = [super init];
    if(self) {
        self->thread = nil;
        self->connection = nil;
        self->notificationQueue = notificationQueue;
        self->networkManager = networkManager;
        self->resourceLock = [ResourceLock new];
        self->_configuration = configuration;
    }
    return self;
}
-(void)boot {
    [resourceLock aquireLock];
    if([thread isExecuting] && ![thread isCancelled]) {
        [resourceLock releaseLock];
        return;
    }
    @try {
        identity = [networkManager clientIdentityToHost:[NSString stringWithCString:_configuration.address
                                                                                 encoding:NSUTF8StringEncoding]
                                               withPort:_configuration.port];
    } @catch (IdentityCreationException *exception) {
        [BootingException exceptionWithName:@"BootingException"
                                     reason:exception.reason
                                   userInfo:nil];
    }
    thread = [[NSThread alloc] initWithTarget:self
                                     selector:@selector(serve)
                                       object:nil];
    thread.name = @"ClientThread";
    [thread start];
    [resourceLock releaseLock];

}
-(void)serve {
    while(YES) {
        [resourceLock aquireLock];
        if(!thread.cancelled) {
            if (connection == nil) {
                
                if ([networkManager connect:identity]) {
                    Connection * newConnection = [[Connection alloc] initWithIdentity:identity
                                                                            chunkSize:_configuration.chunkSize
                                                                    notificationQueue:notificationQueue
                                                                       networkManager:networkManager];
                    connection = newConnection;
                    [resourceLock releaseLock];
                    __weak Client * weakSelf = self;
                    dispatch_async(notificationQueue, ^{
                        [weakSelf.delegate connectionHasBeenEstablished:newConnection];
                    });
                    [resourceLock aquireLock];
                }
            } else {
                [connection performIO];
            }
        } else {
            [resourceLock releaseLock];
            break;
        }
        [resourceLock releaseLock];
        usleep(_configuration.eventLoopMicrosecondsDelay);
    }
    [resourceLock aquireLock];
    if (connection) {
        [connection close];
    }
    [resourceLock releaseLock];
}
-(BOOL)isRunning {
    [resourceLock aquireLock];
    BOOL running = thread && thread.isExecuting;
    [resourceLock releaseLock];
    return running;
}
-(void)shutDown {
    [resourceLock aquireLock];
    [thread cancel];
    while([thread isExecuting]) {
        [resourceLock releaseLock];
        usleep(_configuration.eventLoopMicrosecondsDelay);
        [resourceLock aquireLock];
    }
    connection = nil;
    [resourceLock releaseLock];
}
@end

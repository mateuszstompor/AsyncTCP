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
#import "NetworkWrapper.h"
#import "NetworkManager.h"
#import "IONetworkHandler.h"
#import "SocketOptionsWrapper.h"
#import "DescriptorControlWrapper.h"

#include <arpa/inet.h>

@interface Client()
{
    NSLock * resourceLock;
    dispatch_queue_t notificationQueue;
    NSThread * thread;
    Identity* identity;
    Connection * connection;
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
                        networkManager:[NetworkManager new]];
}
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager {
    self = [super init];
    if(self) {
        self->thread = nil;
        self->connection = nil;
        self->notificationQueue = notificationQueue;
        self->networkManager = networkManager;
        self->resourceLock = [NSLock new];
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
    [resourceLock unlock];

}
-(void)serve {
    while(YES) {
        [resourceLock lock];
        if(!thread.cancelled) {
            if (connection == nil) {
                
                if ([networkManager connect:identity]) {
                    Connection * newConnection = [[Connection alloc] initWithIdentity:identity
                                                                            chunkSize:_configuration.chunkSize
                                                                    notificationQueue:notificationQueue
                                                                       networkManager:networkManager];
                    connection = newConnection;
                    [resourceLock unlock];
                    __weak Client * weakSelf = self;
                    dispatch_async(notificationQueue, ^{
                        [weakSelf.delegate connectionHasBeenEstablished:newConnection];
                    });
                    [resourceLock lock];
                }
            } else {
                [connection performIO];
            }
        } else {
            [resourceLock unlock];
            break;
        }
        [resourceLock unlock];
        usleep(_configuration.eventLoopMicrosecondsDelay);
    }
    [resourceLock lock];
    if (connection) {
        [connection close];
    }
    [resourceLock unlock];
}
-(BOOL)isRunning {
    [resourceLock lock];
    BOOL running = thread && thread.isExecuting;
    [resourceLock unlock];
    return running;
}
-(void)shutDown {
    [resourceLock lock];
    [thread cancel];
    while([thread isExecuting]) {
        [resourceLock unlock];
        usleep(_configuration.eventLoopMicrosecondsDelay);
        [resourceLock lock];
    }
    connection = nil;
    [resourceLock unlock];
}
@end

//
//  Client.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Client.h"
#import "Thread.h"
#import "Dispatch.h"
#import "Connection.h"
#import "Exceptions.h"
#import "ResourceLock.h"
#import "SystemWrapper.h"
#import "ThreadFactory.h"
#import "NetworkWrapper.h"
#import "NetworkManager.h"
#import "IONetworkHandler.h"
#import "ResourceLockFactory.h"
#import "SocketOptionsWrapper.h"
#import "DescriptorControlWrapper.h"

#import <arpa/inet.h>

@interface Client()
{
    Identity* identity;
    Connection * connection;
    NSObject<Threadable> * thread;
    NSObject<Lockable> * resourceLock;
    NSObject<LockProducible> * lockFactory;
    NSObject<ThreadProducible> * threadFactory;
    NSObject<Dispatchable> * notificationQueue;
    NSObject<NetworkManageable> * networkManager;
    NSObject<SystemWrappable> * systemWrapper;
}
@end

@implementation Client
-(instancetype)initWithConfiguration:(ClientConfiguration *)configuration {
    return [self initWithConfiguration:configuration notificationQueue:dispatch_get_main_queue()];
}
-(instancetype)initWithConfiguration:(ClientConfiguration *)configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue {
    return [self initWithConfiguration:configuration
                     notificationQueue:[[Dispatch alloc] initWithDispatchQueue:notificationQueue]
                        networkManager:[NetworkManager new]
                           lockFactory:[ResourceLockFactory new]
                         threadFactory:[ThreadFactory new]
                         systemWrapper:[SystemWrapper new]];
}
-(instancetype)initWithConfiguration: (ClientConfiguration *) configuration
                   notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager
                         lockFactory: (NSObject<LockProducible>*) lockFactory
                       threadFactory: (NSObject<ThreadProducible>*) threadFactory
                       systemWrapper: (NSObject<SystemWrappable> *) systemWrapper {
    self = [super init];
    if(self) {
        self->identity = nil;
        self->thread = nil;
        self->connection = nil;
        self->notificationQueue = notificationQueue;
        self->networkManager = networkManager;
        self->threadFactory = threadFactory;
        self->lockFactory = lockFactory;
        self->resourceLock = [lockFactory newLock];
        self->systemWrapper = systemWrapper;
        self->_configuration = configuration;
    }
    return self;
}
-(void)boot {
    [resourceLock aquireLock];
    if(thread != nil) {
        [resourceLock releaseLock];
        return;
    }
    @try {
        identity = [networkManager clientIdentityToHost:_configuration.address
                                               withPort:_configuration.port];
    } @catch (IdentityCreationException *exception) {
        [BootingException exceptionWithName:@"BootingException"
                                     reason:exception.reason
                                   userInfo:nil];
    }
    thread = [threadFactory createNewThreadWithTarget:self
                                             selector:@selector(serve)
                                                 name:@"ClientThread"];
    [thread start];
    [resourceLock releaseLock];
}
-(void)serve {
    while(YES) {
        [resourceLock aquireLock];
        if(!thread.cancelled) {
            if (connection == nil || [connection state] == closed) {
                if ([networkManager connect:identity]) {
                    Connection * newConnection = [[Connection alloc] initWithIdentity:identity
                                                                            chunkSize:_configuration.chunkSize
                                                                    notificationQueue:notificationQueue
                                                                       networkManager:networkManager
                                                                         resourceLock:[lockFactory newLock]];
                    connection = newConnection;
                    [resourceLock releaseLock];
                    __weak Client * weakSelf = self;
                    [notificationQueue async:^{
                        [weakSelf.delegate connectionHasBeenEstablished:newConnection];
                    }];
                    [resourceLock aquireLock];
                } else if (![networkManager isValidAndHealthy:identity]) {
                    [networkManager close:identity];
                    @try {
                        identity = [networkManager clientIdentityToHost:_configuration.address
                                                               withPort:_configuration.port];
                    } @catch (IdentityCreationException * exception) { }
                }
            } else {
                if ([self shouldBeClosed:connection]) {
                    [connection close];
                    __weak Client * weakSelf = self;
                    Connection * conn = connection;
                    [notificationQueue async:^{
                        [weakSelf.delegate connectionHasBeenClosed: conn];
                    }];
                } else {
                    [connection performIO];
                }
            }
        } else {
            [resourceLock releaseLock];
            break;
        }
        [resourceLock releaseLock];
        [systemWrapper waitMicroseconds:_configuration.eventLoopMicrosecondsDelay];
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
-(void)shutDown: (BOOL) waitForClientThread {
    [resourceLock aquireLock];
    if(thread != nil) {
        [thread cancel];
        if(waitForClientThread) {
            while([thread isExecuting]) {
                [resourceLock releaseLock];
                [systemWrapper waitMicroseconds:_configuration.eventLoopMicrosecondsDelay];
                [resourceLock aquireLock];
            }
        }
        thread = nil;
    }
    if(connection != nil && connection.state != closed) {
        [connection close];
        __weak Client * weakSelf = self;
        Connection * conn = connection;
        [notificationQueue async:^{
            [weakSelf.delegate connectionHasBeenClosed: conn];
        }];
    }
    if(identity != nil) {
        [networkManager close:identity];
        identity = nil;
    }
    [resourceLock releaseLock];
}
-(BOOL)shouldBeClosed: (Connection *) connection {
    return [connection totalErrorsInRow] > _configuration.errorsBeforeConnectionClosing ||
    [self hasConnectionTimedOut: connection] ||
    [connection isClosed];
}
-(BOOL)hasConnectionTimedOut: (Connection *) connection {
    return [connection lastInteractionInterval] > _configuration.connectionTimeout;
}
@end

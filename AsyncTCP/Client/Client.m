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
-(instancetype)initWithConfiguration:(struct ClientConfiguration)configuration {
    return [self initWithConfiguration:configuration notificationQueue:dispatch_get_main_queue()];
}
-(instancetype)initWithConfiguration:(struct ClientConfiguration)configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue {
    return [self initWithConfiguration:configuration
                     notificationQueue:[[Dispatch alloc] initWithDispatchQueue:notificationQueue]
                        networkManager:[NetworkManager new]
                           lockFactory:[ResourceLockFactory new]
                         threadFactory:[ThreadFactory new]
                         systemWrapper:[SystemWrapper new]];
}
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration
                   notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager
                         lockFactory: (NSObject<LockProducible>*) lockFactory
                       threadFactory: (NSObject<ThreadProducible>*) threadFactory
                       systemWrapper: (NSObject<SystemWrappable> *) systemWrapper {
    self = [super init];
    if(self) {
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
        NSString * host = [NSString stringWithCString:_configuration.address
                                             encoding:NSUTF8StringEncoding];
        identity = [networkManager clientIdentityToHost:host
                                               withPort:_configuration.port];
    } @catch (IdentityCreationException *exception) {
        [BootingException exceptionWithName:@"BootingException"
                                     reason:exception.reason
                                   userInfo:nil];
    }
    
    thread = [threadFactory createNewThreadWithTarget:self selector:@selector(serve) name:@"ClientThread"];
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
                                                                       networkManager:networkManager
                                                                         resourceLock:[lockFactory newLock]];
                    connection = newConnection;
                    [resourceLock releaseLock];
                    __weak Client * weakSelf = self;
                    [notificationQueue async:^{
                        [weakSelf.delegate connectionHasBeenEstablished:newConnection];
                    }];
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
    connection = nil;
    [resourceLock releaseLock];
}
@end

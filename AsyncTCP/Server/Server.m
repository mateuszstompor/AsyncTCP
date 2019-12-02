//
//  Server.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Server.h"

#import <netdb.h>

#import "Dispatch.h"
#import "Exceptions.h"
#import "ResourceLock.h"
#import "ThreadFactory.h"
#import "NetworkManager.h"
#import "NetworkWrapper.h"
#import "IONetworkHandler.h"
#import "ResourceLockFactory.h"
#import "DescriptorControlWrapper.h"

@interface Server()
{
    Identity * identity;
    NSObject<Threadable> * thread;
    NSObject<Lockable> * resourceLock;
    NSMutableArray<Connection*> * connections;
    NSObject<Dispatchable> * notificationQueue;
    NSObject<ThreadProducible> * threadFactory;
    NSObject<LockProducible> * lockFactory;
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
                     notificationQueue:[[Dispatch alloc] initWithDispatchQueue: notificationQueue]
                        networkManager:[NetworkManager new]
                         threadFactory:[ThreadFactory new]
                           lockFactory:[ResourceLockFactory new]];
}
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration
                   notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager
                       threadFactory: (NSObject<ThreadProducible>*) threadFactory
                         lockFactory: (NSObject<LockProducible>*) lockFactory {
    self = [super init];
    if (self) {
        NSAssert([networkManager hasPortValidRange: configuration.port],
                 @"Port number is not within the valid range");
        self->identity = nil;
        self->thread = nil;
        self->lockFactory = lockFactory;
        self->threadFactory = threadFactory;
        self->resourceLock = [lockFactory newLock];
        self->networkManager = networkManager;
        self->notificationQueue = notificationQueue;
        self->connections = [NSMutableArray new];
        self->_delegate = nil;
        self->_configuration = configuration;
    }
    return self;
}
-(void)boot {
    [resourceLock aquireLock];
    if(thread) {
        [resourceLock releaseLock];
        return;
    }
    if (identity == nil || ![networkManager isValidAndHealthy:identity]) {
        @try {
            identity = [networkManager localIdentityOnPort: _configuration.port
                                   maximalConnectionsCount:_configuration.maximalConnectionsCount];
        } @catch (IdentityCreationException * exception) {
            [resourceLock releaseLock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:exception.reason
                                              userInfo:nil];
        }
    }
    thread = [threadFactory createNewThreadWithTarget:self selector:@selector(serve) name:@"ServerThread"];
    [thread start];
    [resourceLock releaseLock];
}
-(void)serve {
    while(YES) {
        [resourceLock aquireLock];
        if(thread != nil && !thread.cancelled) {
            NSMutableArray<Connection*>* connectionsToRemove = [NSMutableArray new];
            // perform IO
            for (Connection * connection in connections) {
                if ([self shouldBeClosed:connection]) {
                    [connectionsToRemove addObject:connection];
                } else {
                    [connection performIO];
                }
            }
            [self unsafeCloseConnectionsWithNotifying: connectionsToRemove];
            for (Connection * connection in connectionsToRemove) {
                [connections removeObject:connection];
            }
            // accept new connections if amount of clients do not exceeds max
            if (self.configuration.maximalConnectionsCount > [connections count] && _delegate != nil) {
                Identity * newClientIdentity = [networkManager acceptNewIdentity:identity];
                if (newClientIdentity) {
                    Connection * connection = [[Connection alloc] initWithIdentity:newClientIdentity
                                                                         chunkSize:_configuration.chunkSize
                                                                 notificationQueue:notificationQueue
                                                                    networkManager:networkManager
                                                                      resourceLock:[lockFactory newLock]];
                    __weak Server * weakSelf = self;
                    [notificationQueue async:^{
                        [weakSelf.delegate newClientHasConnected:connection];
                    }];
                    [connections addObject:connection];
                }
            }
        } else {
            [resourceLock releaseLock];
            break;
        }
        [resourceLock releaseLock];
        usleep(_configuration.eventLoopMicrosecondsDelay);
    }
}
-(BOOL)shouldBeClosed: (Connection *) connection {
    return [connection totalErrorsInRow] > _configuration.errorsBeforeConnectionClosing ||
    [self hasConnectionTimedOut: connection] ||
    [connection isClosed];
}
-(void)unsafeCloseConnectionsWithNotifying: (NSArray<Connection *>*) connectionsToClose {
    __weak Server * weakSelf = self;
    for (Connection * connection in connectionsToClose) {
        [connection close];
        [notificationQueue async:^{
            [weakSelf.delegate clientHasDisconnected:connection];
        }];
    }
}
-(void)shutDown: (BOOL) waitForServerThread {
    [resourceLock aquireLock];
    if(thread != nil) {
        [thread cancel];
        // wait for server to shutdown
        if(waitForServerThread) {
            while([thread isExecuting]) {
                [resourceLock releaseLock];
                usleep(self.configuration.eventLoopMicrosecondsDelay);
                [resourceLock aquireLock];
            }
        }
        thread = nil;
    }
    if([connections count] > 0) {
        [self unsafeCloseConnectionsWithNotifying: connections];
        [connections removeAllObjects];
    }
    if(identity != nil) {
        BOOL closedSuccessfully = [networkManager close:identity];
        identity = nil;
        if (!closedSuccessfully) {
            [resourceLock releaseLock];
            @throw [ShuttingDownException exceptionWithName:@"ShuttingDownException"
                                                     reason:@"Could not close server's socket" userInfo:nil];
        }
    }
    [resourceLock releaseLock];
}
-(NSInteger)connectedClientsCount {
    [resourceLock aquireLock];
    NSInteger count = [connections count];
    [resourceLock releaseLock];
    return count;
}
-(BOOL)isRunning {
    [resourceLock aquireLock];
    BOOL running = thread && thread.isExecuting;
    [resourceLock releaseLock];
    return running;
}
-(BOOL)hasConnectionTimedOut: (Connection *) connection {
    return [connection lastInteractionInterval] > _configuration.connectionTimeout;
}
@end

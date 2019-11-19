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
    int descriptor;
    NSThread * thread;
    NSLock * resourceLock;
    struct sockaddr_in address;
    dispatch_queue_t notificationQueue;
    NSMutableArray<Connection*>* connections;
    NSObject<IONetworkHandleable>* ioHandler;
    NSObject<NetworkManageable>* networkManager;
    NSObject<NetworkWrappable>* networkWrapper;
    NSObject<SocketOptionsWrappable>* socketOptionsWrapper;
    NSObject<DescriptorControlWrappable>* descriptorControlWrapper;
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
                             ioHandler:[IONetworkHandler new]
                        networkManager:[NetworkManager new]
              descriptorControlWrapper:[DescriptorControlWrapper new]
                  socketOptionsWrapper:[SocketOptionsWrapper new]
                        networkWrapper:[NetworkWrapper new]];
}
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                           ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
                      networkManager: (NSObject<NetworkManageable>*) networkManager
            descriptorControlWrapper: (NSObject<DescriptorControlWrappable>*) descriptorControlWrapper
                socketOptionsWrapper: (NSObject<SocketOptionsWrappable>*) socketOptionsWrapper
                      networkWrapper: (NSObject<NetworkWrappable>*) networkWrapper {
    self = [super init];
    if (self) {
        NSAssert([networkManager hasPortValidRange: configuration.port],
                 @"Port number should be within the range");
        self->descriptor = -1;
        self->thread = nil;
        self->ioHandler = ioHandler;
        self->resourceLock = [NSLock new];
        self->networkManager = networkManager;
        self->networkWrapper = networkWrapper;
        self->connections = [NSMutableArray new];
        self->notificationQueue = notificationQueue;
        self->socketOptionsWrapper = socketOptionsWrapper;
        self->descriptorControlWrapper = descriptorControlWrapper;
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
    if (![networkManager isValidOpenFileDescriptor:descriptor]) {
        descriptor = [networkWrapper socket];
        if (descriptor < 0) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not create a new socket" userInfo:nil];
        }
        address = [networkManager localServerIdentityWithPort:self.configuration.port];
        if ([socketOptionsWrapper reuseAddress:descriptor] == -1) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not reuse exisitng address" userInfo:nil];
        }
        if ([socketOptionsWrapper reusePort:descriptor] == -1) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not reuse exisitng port" userInfo:nil];
        }
        if ([socketOptionsWrapper noSigPipe:descriptor] == -1) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not protect against sigPipe" userInfo:nil];
        }
        if ([descriptorControlWrapper makeNonBlocking:descriptor] == -1) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not make the socket nonblocking" userInfo:nil];
        }
        if([networkWrapper bind:descriptor withAddress:(struct sockaddr *)&address length:sizeof(struct sockaddr_in)] < 0) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not bind the address" userInfo:nil];
        }
        if([networkWrapper listen:descriptor maximalConnectionsCount:self.configuration.maximalConnectionsCount] < 0) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not listen for new clients" userInfo:nil];
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
                struct sockaddr_in clientAddress;
                socklen_t clientAddressLength;
                int clientSocketDescriptor;
                memset(&clientAddress, 0, sizeof(struct sockaddr_in));
                clientSocketDescriptor = [networkWrapper accept:descriptor
                                                    withAddress:(struct sockaddr *)&clientAddress
                                                         length:&clientAddressLength];
                if(clientSocketDescriptor >= 0
                   && [socketOptionsWrapper noSigPipe:clientSocketDescriptor] != -1
                   && [descriptorControlWrapper makeNonBlocking:clientSocketDescriptor] != -1) {
                    Connection * connection = [[Connection alloc] initWithAddress:clientAddress
                                                                    addressLength:clientAddressLength
                                                                       descriptor:clientSocketDescriptor
                                                                        chunkSize:self.configuration.chunkSize
                                                                notificationQueue: notificationQueue
                                                                        ioHandler:ioHandler
                                                                   networkManager:networkManager
                                                                   networkWrapper:networkWrapper];
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
    if (![networkManager close:descriptor]) {
        [resourceLock unlock];
        @throw [ShuttingDownException exceptionWithName:@"ShuttingDownException"
                                                 reason:@"Could close server's socket" userInfo:nil];
    }
    descriptor = -1;
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

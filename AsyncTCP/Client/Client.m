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
    Connection * connection;
    NSObject<DescriptorControlWrappable> * descriptorControlWrapper;
    NSObject<SocketOptionsWrappable> * socketOptionsWrapper;
    NSObject<NetworkManageable>* networkManager;
    NSObject<IONetworkHandleable>* ioHandler;
    NSObject<NetworkWrappable>* networkWrapper;
    int clientSocket;
    struct sockaddr_in server_addr;
    socklen_t server_addr_len;
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
                             ioHandler:[IONetworkHandler new]
                        networkManager:[NetworkManager new]
              descriptorControlWrapper:[DescriptorControlWrapper new]
                  socketOptionsWrapper:[SocketOptionsWrapper new]
                        networkWrapper:[NetworkWrapper new]];
}
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                           ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
                      networkManager: (NSObject<NetworkManageable>*) networkManager
            descriptorControlWrapper: (NSObject<DescriptorControlWrappable>*) descriptorControlWrapper
                socketOptionsWrapper: (NSObject<SocketOptionsWrappable>*) socketOptionsWrapper
                      networkWrapper: (NSObject<NetworkWrappable>*) networkWrapper {
    self = [super init];
    if(self) {
        self->thread = nil;
        self->connection = nil;
        self->clientSocket = -1;
        self->notificationQueue = notificationQueue;
        self->descriptorControlWrapper = descriptorControlWrapper;
        self->socketOptionsWrapper = socketOptionsWrapper;
        self->ioHandler = ioHandler;
        self->networkManager = networkManager;
        self->resourceLock = [NSLock new];
        self->networkWrapper = networkWrapper;
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
    self->server_addr_len = sizeof(struct sockaddr_in);
    @try {
        self->server_addr = [networkManager identityWithHost:[NSString stringWithCString:_configuration.address
                                                                                encoding:NSUTF8StringEncoding]
                                                    withPort:_configuration.port];
    } @catch (IdentityCreationException *exception) {
        [BootingException exceptionWithName:@"BootingException" reason:@"Could not resolve address" userInfo:nil];
    }
    if((clientSocket = [networkWrapper socket]) < 0) {
        [BootingException exceptionWithName:@"BootingException" reason:@"Could not create socket" userInfo:nil];
    }
    if ([descriptorControlWrapper makeNonBlocking:clientSocket] == -1) {
        [BootingException exceptionWithName:@"BootingException" reason:@"Could not make socket non blocking" userInfo:nil];
    }
    if ([socketOptionsWrapper noSigPipe:clientSocket] == -1) {
        [BootingException exceptionWithName:@"BootingException" reason:@"Could not avoid sigpipe" userInfo:nil];
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
                if ([networkWrapper connect:clientSocket
                                withAddress:(struct sockaddr const *)&server_addr
                                     length:server_addr_len] > 0) {
                    Identity * identity = [[Identity alloc] initWithDescriptor:clientSocket
                                                                 addressLength:server_addr_len
                                                                       address:server_addr];
                    Connection * newConnection = [[Connection alloc] initWithIdentity: identity
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
        usleep(self.configuration.eventLoopMicrosecondsDelay);
    }
    [resourceLock lock];
    if (connection) {
        [self->connection close];
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
        usleep(self.configuration.eventLoopMicrosecondsDelay);
        [resourceLock lock];
    }
    clientSocket = -1;
    connection = nil;
    [resourceLock unlock];
}
@end

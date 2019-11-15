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
#import "NetworkManager.h"
#import "IONetworkHandler.h"
#import "FileDescriptorConfigurator.h"

#include <arpa/inet.h>

@interface Client()
{
    NSLock * resourceLock;
    dispatch_queue_t notificationQueue;
    struct ClientConfiguration configuration;
    NSThread * thread;
    Connection * connection;
    NSObject<FileDescriptorConfigurable> * fileDescriptorConfigurator;
    NSObject<NetworkManageable>* networkManager;
    NSObject<IONetworkHandleable>* ioHandler;
    int clientSocket;
    struct sockaddr_in server_addr;
    socklen_t server_addr_len;
}
@end

@implementation Client
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                           ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
          fileDescriptorConfigurator: (NSObject<FileDescriptorConfigurable>*) fileDescriptorConfigurator
                      networkManager: (NSObject<NetworkManageable>*) networkManager {
    self = [super init];
    if(self) {
        self->thread = nil;
        self->connection = nil;
        self->clientSocket = -1;
        self->notificationQueue = notificationQueue;
        self->configuration = configuration;
        self->fileDescriptorConfigurator = fileDescriptorConfigurator;
        self->resourceLock = [NSLock new];
    }
    return self;
}
-(instancetype)initWithConfiguration:(struct ClientConfiguration)configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue {
    return [self initWithConfiguration:configuration
                     notificationQueue:notificationQueue
                             ioHandler:[IONetworkHandler new]
            fileDescriptorConfigurator:[FileDescriptorConfigurator new]
                        networkManager:[NetworkManager new]];
}
-(instancetype)initWithConfiguration:(struct ClientConfiguration)configuration {
    return [self initWithConfiguration:configuration notificationQueue:dispatch_get_main_queue()];
}
-(void)boot {
    [resourceLock lock];
    if([thread isExecuting] && ![thread isCancelled]) {
        [resourceLock unlock];
        return;
    }
    self->server_addr_len = sizeof(struct sockaddr_in);
    @try {
        self->server_addr = [networkManager identityWithHost:configuration.address withPort:configuration.port];
    } @catch (IdentityCreationException *exception) {
        [BootingException exceptionWithName:@"BootingException" reason:@"Could not resolve address" userInfo:nil];
    }
    if((clientSocket = [networkManager socket]) < 0) {
        [BootingException exceptionWithName:@"BootingException" reason:@"Could not create socket" userInfo:nil];
    }
    thread = [[NSThread alloc] initWithTarget:self
                                     selector:@selector(serve)
                                       object:nil];
    thread.name = @"ClientThread";
    [thread start];
    [resourceLock unlock];

}
-(void)serve {
    while(true) {
        [resourceLock lock];
        if(!thread.cancelled) {
            if (connection == nil) {
                if ([networkManager connect:clientSocket
                                withAddress:(struct sockaddr const *)&server_addr
                                     length:server_addr_len] > 0) {
                    Connection * newConnection = [[Connection alloc] initWithAddress:self->server_addr
                                                                       addressLength:self->server_addr_len
                                                                          descriptor:self->clientSocket
                                                                           chunkSize:configuration.chunkSize
                                                                   notificationQueue:notificationQueue
                                                                           ioHandler:ioHandler
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
        usleep(configuration.eventLoopMicrosecondsDelay);
    }
    [resourceLock lock];
    if (connection) {
        [self->connection close];
    }
    [resourceLock unlock];
}
-(struct ClientConfiguration)configuration {
    [resourceLock lock];
    struct ClientConfiguration config = self->configuration;
    [resourceLock unlock];
    return config;
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
        usleep(configuration.eventLoopMicrosecondsDelay);
        [resourceLock lock];
    }
    clientSocket = -1;
    connection = nil;
    [resourceLock unlock];
}
@end

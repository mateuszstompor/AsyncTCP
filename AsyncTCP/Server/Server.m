//
//  Server.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Server.h"

#import <netdb.h>

#import "../IO/IONetworkHandler.h"
#import "../NetworkManager/NetworkManager.h"
#import "../FileDescriptors/FileDescriptorConfigurator.h"

@implementation BootingException
@end

@implementation ShuttingDownException
@end

@interface Server()
{
    int descriptor;
    struct sockaddr_in address;
    NSThread * thread;
    NSLock * resourceLock;
    struct ServerConfiguration configuration;
    NSMutableArray<Connection*>* connections;
    NSObject<IONetworkHandleable>* ioHandler;
    NSObject<FileDescriptorConfigurable>* fileDescriptorConfigurator;
    NSObject<NetworkManageable>* networkManager;
    dispatch_queue_t notificationQueue;
}
@end

@implementation Server
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration {
    return [self initWithConfiguratoin:configuration
                     notificationQueue: dispatch_get_main_queue()
                             ioHandler:[[IONetworkHandler alloc] init]
            fileDescriptorConfigurator:[[FileDescriptorConfigurator alloc] init]
                        networkManager:[[NetworkManager alloc] init]];
}
- (instancetype)initWithConfiguratoin:(struct ServerConfiguration)configuration
                    notificationQueue: (dispatch_queue_t) notificationQueue
                            ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
           fileDescriptorConfigurator: (NSObject<FileDescriptorConfigurable>*) fileDescriptorConfigurator
                       networkManager: (NSObject<NetworkManageable>*) networkManager {
    self = [super init];
    if (self) {
        NSAssert([networkManager isPortInRange: configuration.port], @"Port number should be within the range");
        self->descriptor = -1;
        self->configuration = configuration;
        self->connections = [NSMutableArray new];
        self->resourceLock = [NSLock new];
        self->thread = nil;
        self->notificationQueue = notificationQueue;
        self->fileDescriptorConfigurator = fileDescriptorConfigurator;
        self->ioHandler = ioHandler;
        self->_delegate = nil;
        self->networkManager = networkManager;
    }
    return self;
}
-(void)boot {
    [resourceLock lock];
    if (![networkManager isValidOpenFileDescriptor:descriptor]) {
        descriptor = socket(AF_INET, SOCK_STREAM, 0);
        if (descriptor < 0) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not create a new socket" userInfo:nil];
        }
        address = [networkManager localServerAddressWithPort:configuration.port];
        if (![fileDescriptorConfigurator reuseAddress:descriptor]) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not reuse exisitng address" userInfo:nil];
        }
        if (![fileDescriptorConfigurator noSigPipe:descriptor]) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not protect against sigPipe" userInfo:nil];
        }
        if (![fileDescriptorConfigurator makeNonBlocking:descriptor]) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not make the socket nonblocking" userInfo:nil];
        }
        if(bind(descriptor, (struct sockaddr *)&address, sizeof(struct sockaddr_in)) < 0) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not bind the address" userInfo:nil];
        }
        if(listen(descriptor, configuration.maximalConnectionsCount) < 0 ) {
            [resourceLock unlock];
            @throw [BootingException exceptionWithName:@"BootingException"
                                                reason:@"Could not listen for new clients" userInfo:nil];
        }
    }
    thread = [[NSThread alloc] initWithTarget:self
                                     selector:@selector(serve)
                                       object:nil];
    thread.name = @"ServerThread";
    [resourceLock unlock];
    [thread start];
}
-(void)serve {
    while(true) {
        [resourceLock lock];
        if(!thread.cancelled) {
            NSMutableArray<Connection*>* connectionsToRemove = [NSMutableArray new];
            // perform IO
            for (ssize_t i=0; i<[connections count]; ++i) {
                Connection * connection = [connections objectAtIndex:i];
                if ([connection lastInteractionInterval] > configuration.connectionTimeout) {
                    [connection close];
                }
                if (connection.state == closed) {
                    [connectionsToRemove addObject:connection];
                } else {
                    [connection performIO];
                }
            }
            // remove timed out or not open connections
            for (Connection * connection in connectionsToRemove) {
                [connections removeObject:connection];
            }
            // accept new connections if amount of clients do not exceeds max
            if (configuration.maximalConnectionsCount > [connections count] && _delegate != nil) {
                struct sockaddr_in clientAddress;
                socklen_t clientAddressLength;
                int clientSocketDescriptor;
                memset(&clientAddress, 0, sizeof(struct sockaddr_in));
                clientSocketDescriptor = accept(descriptor, (struct sockaddr *)&clientAddress, &clientAddressLength);
                if(clientSocketDescriptor >= 0
                   && [fileDescriptorConfigurator noSigPipe:clientSocketDescriptor]
                   && [fileDescriptorConfigurator makeNonBlocking:clientSocketDescriptor]) {
                    Connection * connection = [[Connection alloc] initWithAddress:clientAddress
                                                                    addressLength:clientAddressLength
                                                                       descriptor:clientSocketDescriptor
                                                                        chunkSize:configuration.chunkSize
                                                                notificationQueue: notificationQueue
                                                                        ioHandler:ioHandler
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
        usleep(configuration.eventLoopMicrosecondsDelay);
    }
}
-(void)shutDown {
    [thread cancel];
    [resourceLock lock];
    for (Connection * connection in connections) {
        [connection close];
    }
    if (![networkManager close:descriptor]) {
        [resourceLock unlock];
        @throw [ShuttingDownException exceptionWithName:@"ShuttingDownException"
                                                 reason:@"Could close server's socket" userInfo:nil];
    }
    descriptor = -1;
    [resourceLock unlock];
}
-(struct ServerConfiguration)configuration {
    [resourceLock lock];
    struct ServerConfiguration configurationToReturn = configuration;
    [resourceLock unlock];
    return configurationToReturn;
}
@end
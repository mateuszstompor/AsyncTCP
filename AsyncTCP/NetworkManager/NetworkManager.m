//
//  NetworkManager.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "NetworkManager.h"

#import <netdb.h>
#import <errno.h>
#import <stdint.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/socket.h>

#import "Connection.h"
#import "Exceptions.h"

@interface NetworkManager()
{
    NSObject<SocketOptionsWrappable>* socketOptionsWrapper;
    NSObject<DescriptorControlWrappable>* descriptorControlWrapper;
    NSObject<NetworkWrappable>* networkWrapper;
    NSObject<IONetworkHandleable>* ioNetworkHandler;
}
@end

@implementation NetworkManager
-(instancetype)initWithSocketOptionsWrapper: (NSObject<SocketOptionsWrappable>*) socketOptionsWrapper
                   descriptorControlWrapper: (NSObject<DescriptorControlWrappable>*) descriptorControlWrapper
                             networkWrapper: (NSObject<NetworkWrappable>*) networkWrapper
                           ioNetworkHandler: (NSObject<IONetworkHandleable>*) ioNetworkHandler {
    self = [super init];
    if(self) {
        self->socketOptionsWrapper = socketOptionsWrapper;
        self->descriptorControlWrapper = descriptorControlWrapper;
        self->networkWrapper = networkWrapper;
        self->ioNetworkHandler = ioNetworkHandler;
    }
    return self;
}
-(BOOL)hasPortValidRange: (int) port {
    return port > 0 && port < 65535;
}
-(struct sockaddr_in)localServerIdentityWithPort: (int) port {
    return [self identityWithAddress:INADDR_ANY withPort:port];
}
-(struct sockaddr_in)identityWithAddress: (in_addr_t) address withPort: (int) port {
    struct sockaddr_in identity;
    memset(&identity, 0, sizeof(struct sockaddr));
    identity.sin_family = AF_INET;
    identity.sin_addr.s_addr = address;
    identity.sin_port = htons(port);
    return identity;
}
-(struct sockaddr_in)identityWithHost: (NSString*) host withPort: (int) port {
    in_addr_t address = inet_addr([host cStringUsingEncoding:NSASCIIStringEncoding]);
    if((int)address == 0) {
        [IdentityCreationException exceptionWithName:@"IdentityCreationException" reason:@"Could not resolve address" userInfo:nil];
    }
    return [self identityWithAddress: address
                            withPort:port];
}
-(Identity*)clientIdentityToHost: (NSString*) host withPort: (int) port {
    struct sockaddr_in address = [self identityWithHost: host withPort:port];
    int clientSocket;
    if((clientSocket = [networkWrapper socket]) < 0) {
        [IdentityCreationException exceptionWithName:@"IdentityCreationException" reason:@"Could not create socket" userInfo:nil];
    }
    if ([descriptorControlWrapper makeNonBlocking:clientSocket] == -1) {
        [IdentityCreationException exceptionWithName:@"IdentityCreationException" reason:@"Could not make socket non blocking" userInfo:nil];
    }
    if ([socketOptionsWrapper noSigPipe:clientSocket] == -1) {
        [IdentityCreationException exceptionWithName:@"IdentityCreationException" reason:@"Could not avoid sigpipe" userInfo:nil];
    }
    return [[Identity alloc] initWithDescriptor:clientSocket addressLength:sizeof(struct sockaddr_in) address:address];
}
-(Identity *)localIdentityOnPort:(int)port maximalConnectionsCount: (int) maximalConnectionsCount {
    int descriptor = [networkWrapper socket];
    if (descriptor < 0) {
        @throw [IdentityCreationException exceptionWithName:@"IdentityCreationException"
                                                     reason:@"Could not create a new socket" userInfo:nil];
    }
    struct sockaddr_in address = [self localServerIdentityWithPort:port];
    Identity * identity = [[Identity alloc] initWithDescriptor:descriptor addressLength:sizeof(struct sockaddr_in) address:address];
    if ([socketOptionsWrapper reuseAddress:descriptor] == -1) {
        @throw [IdentityCreationException exceptionWithName:@"IdentityCreationException"
                                            reason:@"Could not reuse exisitng address" userInfo:nil];
    }
    if ([socketOptionsWrapper reusePort:descriptor] == -1) {
        @throw [IdentityCreationException exceptionWithName:@"IdentityCreationException"
                                            reason:@"Could not reuse exisitng port" userInfo:nil];
    }
    if ([socketOptionsWrapper noSigPipe:descriptor] == -1) {
        @throw [IdentityCreationException exceptionWithName:@"IdentityCreationException"
                                            reason:@"Could not protect against sigPipe" userInfo:nil];
    }
    if ([descriptorControlWrapper makeNonBlocking:descriptor] == -1) {
        @throw [IdentityCreationException exceptionWithName:@"IdentityCreationException"
                                            reason:@"Could not make the socket nonblocking" userInfo:nil];
    }
    if([networkWrapper bind:descriptor
                withAddress:(struct sockaddr *)&address length:sizeof(struct sockaddr_in)] < 0) {
        @throw [IdentityCreationException exceptionWithName:@"IdentityCreationException"
                                            reason:@"Could not bind the address" userInfo:nil];
    }
    if([networkWrapper listen:descriptor maximalConnectionsCount:maximalConnectionsCount] < 0) {
        @throw [IdentityCreationException exceptionWithName:@"IdentityCreationException"
                                            reason:@"Could not listen for new clients" userInfo:nil];
    }
    return identity;
}
-(Identity*)acceptNewIdentity: (Identity*) serverIdentity {
    struct sockaddr_in clientAddress;
    socklen_t clientAddressLength;
    int clientSocketDescriptor;
    memset(&clientAddress, 0, sizeof(struct sockaddr_in));
    clientSocketDescriptor = [networkWrapper accept:serverIdentity.descriptor
                                        withAddress:(struct sockaddr *)&clientAddress
                                             length:&clientAddressLength];
    if (clientSocketDescriptor != -1) {
        if ([socketOptionsWrapper noSigPipe:clientSocketDescriptor] != -1 &&
            [descriptorControlWrapper makeNonBlocking:clientSocketDescriptor] != -1) {
            return [[Identity alloc] initWithDescriptor:clientSocketDescriptor
                                          addressLength:clientAddressLength
                                                address:clientAddress];
        } else {
            [networkWrapper close:clientSocketDescriptor];
        }
    }
    return nil;
}
-(BOOL)close:(nonnull Identity *)identity {
    if ([self isValidAndHealthy: identity]) {
        return [networkWrapper close:identity.descriptor] >= 0;
    } else {
        return YES;
    }
}
-(BOOL)isValidAndHealthy:(nonnull Identity *)identity {
    return [descriptorControlWrapper descriptorStatus:identity.descriptor] != 0;
}
-(nonnull NSData *)readBytes:(ssize_t)amount identity:(nonnull Identity *)identity {
    return [ioNetworkHandler readBytes:amount fileDescriptor:identity.descriptor];
}
-(nullable NSData *)send:(nonnull NSData *)data identity:(nonnull Identity *)identity {
    return [ioNetworkHandler send:data fileDescriptor:identity.descriptor];
}
-(BOOL)connect: (Identity*) identity {
    return [networkWrapper connect:identity.descriptor
                       withAddress:(struct sockaddr *)identity.addressPointer
                            length:identity.addressLength] != -1;
}
@end

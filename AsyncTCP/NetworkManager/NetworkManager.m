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

@implementation NetworkManager
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
-(BOOL)close: (int) fileDescriptor {
    if ([self isValidOpenFileDescriptor:fileDescriptor]) {
        return close(fileDescriptor) >= 0;
    } else {
        return YES;
    }
}
-(BOOL)isValidOpenFileDescriptor: (int) fileDescriptor {
    return fcntl(fileDescriptor, F_GETFL) != -1;
}
@end

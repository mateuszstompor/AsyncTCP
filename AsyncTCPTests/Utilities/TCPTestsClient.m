//
//  TCPTestsClient.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "TCPTestsClient.h"

#import <netdb.h>
#import <sys/socket.h>

@interface TCPTestsClient()
{
    const char * hostname;
    struct sockaddr_in address;
    socklen_t addressLength;
}
@end

@implementation TCPTestsClient
-(instancetype)initWithHost: (const char *)hostname port: (int) port {
    self = [super init];
    if (self) {
        bzero((char *) &address, sizeof(address));
        struct hostent * server = gethostbyname(hostname);
        if (server == nil) {
            @throw [NSException exceptionWithName:@"HostError"
                                           reason:@"Could not resolve the hostname"
                                         userInfo:nil];
        }
        address.sin_family = AF_INET;
        bcopy((char *)server->h_addr, (char *)&address.sin_addr.s_addr, server->h_length);
        address.sin_port = htons(port);
    }
    return self;
}
-(int)connect {
    _descriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (_descriptor < 0) {
        @throw [NSException exceptionWithName:@"SocketCreationError"
                                       reason:@"Could not create a socket"
                                     userInfo:nil];
    }
    return connect(_descriptor, (struct sockaddr *) &address, sizeof(address));
}
-(ssize_t)send: (char *) data length: (size_t) length {
    return send(_descriptor, data, length, 0);
}
-(ssize_t)readToBuffer: (void *) buffer size: (size_t) size {
    return read(_descriptor, buffer, size);
}
-(int)close {
    return close(_descriptor);
}
@end

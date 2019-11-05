//
//  Utilities.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Utilities.h"

#include <netdb.h>
#include <errno.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h>

#import "Connection.h"

@implementation Utilities
+(BOOL)isPortInRange: (int) port {
    return port > 0 && port < 65535;
}
+(struct sockaddr_in)localServerAddressWithPort: (int) port {
    struct sockaddr_in address;
    memset(&address, 0, sizeof(struct sockaddr));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);
    return address;
}
+(BOOL)makeNonBlocking: (int) fileDescriptor {
    return fcntl(fileDescriptor, F_SETFL, O_NONBLOCK) != -1;
}
+(BOOL)noSigPipe: (int) fileDescriptor {
    return setsockopt(fileDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &(int){ 1 }, sizeof(int)) >= 0;
}
+(BOOL)isValidOpenFileDescriptor: (int) fileDescriptor {
    return fcntl(fileDescriptor, F_GETFL) != -1;
}
+(BOOL)reuseAddress:(int)fileDescriptor {
    return setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &(int){ 1 }, sizeof(int)) >= 0;
}
+(BOOL)close: (int) fileDescriptor {
    if ([self isValidOpenFileDescriptor:fileDescriptor]) {
        return close(fileDescriptor) >= 0;
    } else {
        return YES;
    }
}
@end

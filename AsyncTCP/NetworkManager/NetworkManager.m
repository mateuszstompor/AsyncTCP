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
#import <sys/types.h>
#import <sys/socket.h>

#import "Connection.h"

@implementation NetworkManager
-(BOOL)isPortInRange: (int) port {
    return port > 0 && port < 65535;
}
-(struct sockaddr_in)localServerAddressWithPort: (int) port {
    struct sockaddr_in address;
    memset(&address, 0, sizeof(struct sockaddr));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);
    return address;
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

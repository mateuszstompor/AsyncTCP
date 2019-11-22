//
//  NetworkWrapper.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "NetworkWrapper.h"

#import <sys/types.h>
#import <sys/socket.h>

@implementation NetworkWrapper
-(int)socket {
    return socket(AF_INET, SOCK_STREAM, 0);
}
-(int)bind: (int) descriptor withAddress: (struct sockaddr *) address length: (socklen_t) length {
    return bind(descriptor, address, length);
}
-(int)listen: (int) descriptor maximalConnectionsCount: (int) maximalConnectionsCount {
    return listen(descriptor, maximalConnectionsCount);
}
-(int)accept: (int)descriptor withAddress: (struct sockaddr *)address length: (socklen_t *)length {
    return accept(descriptor, address, length);
}
-(int)connect: (int) descriptor withAddress: (struct sockaddr const *) address length: (socklen_t) length {
    return connect(descriptor, address, length);
}
-(ssize_t)send: (int) descriptor buffer: (const void *) buffer size: (size_t) size flags: (int) flags {
    return send(descriptor, buffer, size, flags);
}
-(ssize_t)receive: (int) descirptor buffer: (void *) buffer size: (size_t) size flags: (int) flags {
    return recv(descirptor, buffer, size, flags);
}
-(int)close: (int) fileDescriptor {
    return close(fileDescriptor);
}
-(int)errnoValue {
    return errno;
}
@end

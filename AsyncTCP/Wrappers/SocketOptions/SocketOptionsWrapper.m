//
//  SocketOptionsWrapper.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "SocketOptionsWrapper.h"

#import <netdb.h>
#import <errno.h>

@implementation SocketOptionsWrapper
/*
 setsockopt
 
 RETURN VALUE
 
 On success, zero is returned. On error, -1 is returned, and errno is set appropriately
*/
-(int)noSigPipe: (int) fileDescriptor {
    return [self setsockopt:fileDescriptor option:SO_NOSIGPIPE];
}
-(int)reuseAddress:(int) fileDescriptor {
    return [self setsockopt:fileDescriptor option:SO_REUSEADDR];
}
-(int)reusePort: (int) fileDescriptor {
    return [self setsockopt:fileDescriptor option:SO_REUSEPORT];
}
-(int)setsockopt: (int) fileDescriptor option: (int) option {
    return setsockopt(fileDescriptor, SOL_SOCKET, option, &(int){ 1 }, sizeof(int));
}
@end

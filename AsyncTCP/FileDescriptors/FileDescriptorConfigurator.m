//
//  FileDescriptorConfigurator.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "FileDescriptorConfigurator.h"

#import <netdb.h>
#import <errno.h>


@implementation FileDescriptorConfigurator
-(BOOL)makeNonBlocking: (int) fileDescriptor {
    return fcntl(fileDescriptor, F_SETFL, O_NONBLOCK) != -1;
}
-(BOOL)noSigPipe: (int) fileDescriptor {
    return setsockopt(fileDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &(int){ 1 }, sizeof(int)) >= 0;
}
-(BOOL)isValidOpenFileDescriptor: (int) fileDescriptor {
    return fcntl(fileDescriptor, F_GETFL) != -1;
}
-(BOOL)reuseAddress:(int)fileDescriptor {
    return setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &(int){ 1 }, sizeof(int)) >= 0;
}
@end

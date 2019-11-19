//
//  DescriptorControlWrapper.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "DescriptorControlWrapper.h"

#import <netdb.h>
#import <errno.h>

@implementation DescriptorControlWrapper
/*
 fcntl
 
 RETURN VALUE
 
 For a successful call, the return value depends on the operation:
 
 F_DUPFD  The new file descriptor.
 
 F_GETFD  Value of file descriptor flags.
 
 F_GETFL  Value of file status flags.
 
 F_GETLEASE
 Type of lease held on file descriptor.
 
 F_GETOWN Value of file descriptor owner.
 
 F_GETSIG Value of signal sent when read or write becomes possible, or
 zero for traditional SIGIO behavior.
 
 F_GETPIPE_SZ, F_SETPIPE_SZ
 The pipe capacity.
 
 F_GET_SEALS
 A bit mask identifying the seals that have been set for the
 inode referred to by fd.
 
 All other commands
 Zero.
 
 On error, -1 is returned, and errno is set appropriately.
*/
-(int)makeNonBlocking: (int) fileDescriptor {
    return fcntl(fileDescriptor, F_SETFL, O_NONBLOCK);
}
-(int)descriptorStatus:(int)fileDescriptor {
    return fcntl(fileDescriptor, F_GETFL);
}
@end

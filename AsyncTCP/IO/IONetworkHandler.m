//
//  IONetworkHandler.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "IONetworkHandler.h"

#import "Exceptions.h"
#import "NetworkWrapper.h"

#import <netdb.h>

@interface IONetworkHandler()
{
    NSObject<NetworkWrappable> * networkWrapper;
}
@end

@implementation IONetworkHandler
-(instancetype)init {
    return [self initWithWrapper:[NetworkWrapper new]];
}
-(instancetype)initWithWrapper:(NSObject<NetworkWrappable> *)networkWrapper {
    self = [super init];
    if(self) {
        self->networkWrapper = networkWrapper;
    }
    return self;
}
-(NSData*)send: (NSData*) data fileDescriptor: (int) fileDescriptor {
    uint8_t * rawData = (uint8_t*)[data bytes];
    ssize_t size = sizeof(uint8_t) * data.length;
    ssize_t result = [networkWrapper send:fileDescriptor buffer:rawData size:size flags:0];
    if (result == size) {
        return nil;
    } else if (result > 0) {
        return [data subdataWithRange:NSMakeRange(result, [data length]-result)];
    } else if (result == -1 && ([networkWrapper errnoValue] == EAGAIN || [networkWrapper errnoValue] == EWOULDBLOCK)) {
        return data;
    } else {
        NSString * explanation = [[NSString alloc] initWithFormat:@"Data cannot be sent, errno: %i", errno];
        @throw [IOException exceptionWithName:@"IOException" reason:explanation userInfo:nil];
    }
}
-(NSData*)readBytes: (ssize_t) amount fileDescriptor: (int) fileDescriptor {
    uint8_t buffer[amount];
    ssize_t result = [networkWrapper receive:fileDescriptor buffer:buffer size:amount flags:0];
    if (result > 0) {
        return [NSData dataWithBytes:buffer length:result];
    } else if (result == -1 && ([networkWrapper errnoValue] == EAGAIN || [networkWrapper errnoValue] == EWOULDBLOCK)) {
        return nil;
    } else {
        NSString * explanation = [[NSString alloc] initWithFormat:@"Data cannot be read, errno: %i", errno];
        @throw [IOException exceptionWithName:@"IOException" reason:explanation userInfo:nil];
    }
}
@end

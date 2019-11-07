//
//  IONetworkHandler.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "IONetworkHandler.h"

#import <netdb.h>

@implementation IOException : NSException
@end

@implementation IONetworkHandler
-(BOOL)send: (NSData*) data fileDescriptor: (int) fileDescriptor {
    uint8_t * rawData = (uint8_t*)[data bytes];
    ssize_t size = sizeof(uint8_t) * data.length;
    ssize_t result = send(fileDescriptor, rawData, size, 0);
    if (result == size) {
        return YES;
    } else if (result == -1 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        return NO;
    } else {
        NSString * explanation = [[NSString alloc] initWithFormat:@"Data cannot be sent, errno: %i", errno];
        @throw [IOException exceptionWithName:@"IOException" reason:explanation userInfo:nil];
    }
}
-(NSData*)readBytes: (ssize_t) amount fileDescriptor: (int) fileDescriptor {
    NSData * data = nil;
    uint8_t * buffer = malloc(amount);
    ssize_t result = recv(fileDescriptor, buffer, amount, 0);
    if (result > 0) {
        data = [NSData dataWithBytes:buffer length:result];
        free(buffer);
        return data;
    } else if (result == -1 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        free(buffer);
        return nil;
    } else {
        free(buffer);
        NSString * explanation = [[NSString alloc] initWithFormat:@"Data cannot be read, errno: %i", errno];
        @throw [IOException exceptionWithName:@"IOException" reason:explanation userInfo:nil];
    }
}
@end

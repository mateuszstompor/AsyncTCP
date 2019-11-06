//
//  Connection.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Connection.h"

#import <netdb.h>
#import <errno.h>
#import <stdint.h>
#import <sys/types.h>
#import <sys/socket.h>

#import "ConnectionDelegate.h"

@interface Connection()
{
    int descriptor;
    NSDate * lastActivity;
    NSLock * resourceLock;
    struct sockaddr_in address;
    socklen_t addressLength;
    ConnectionState state;
    ssize_t chunkSize;
    NSObject<IONetworkHandleable>* ioHandler;
    NSMutableArray<NSData*>* outgoingMessages;
    NSObject<NetworkManageable>* networkManager;
}
@end

@implementation Connection
-(instancetype) initWithAddress: (struct sockaddr_in) address
                  addressLength: (socklen_t) addressLength
                     descriptor: (int) descriptor
                      chunkSize: (ssize_t) chunkSize
                      ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
                 networkManager: (NSObject<NetworkManageable>*) networkManager {
    self = [super init];
    if (self) {
        self->descriptor = descriptor;
        self->address = address;
        self->ioHandler = ioHandler;
        self->addressLength = addressLength;
        self->resourceLock = [NSLock new];
        self->lastActivity = nil;
        self->chunkSize = chunkSize;
        self->state = active;
        self->networkManager = networkManager;
        self->outgoingMessages = [NSMutableArray new];
    }
    return self;
}
-(BOOL)enqueueDataForSending: (NSData*) data {
    [resourceLock lock];
    if (state == active) {
        [outgoingMessages addObject:data];
        [resourceLock unlock];
        return YES;
    } else {
        [resourceLock unlock];
        return NO;
    }
}
-(void)requestClosing {
    [resourceLock lock];
    [self unsafeClose];
    [resourceLock unlock];
    [_delegate connection:self stateHasChanged:state];
}
-(void)unsafeClose {
    state = closed;
    close(descriptor);
}
-(ConnectionState)state {
    [resourceLock lock];
    ConnectionState stateToReturn = state;
    [resourceLock unlock];
    return stateToReturn;
}
-(NSTimeInterval)lastInteractionInterval {
    [resourceLock lock];
    NSTimeInterval interval = [[NSDate new] timeIntervalSinceDate:lastActivity];
    [resourceLock unlock];
    return interval;
}
-(void)performIO {
    [resourceLock lock];
    NSData * dataRead = nil;
    BOOL stateChanged = NO;
    @try {
        if ([outgoingMessages count] > 0) {
            NSData * data = [outgoingMessages objectAtIndex:0];
            [outgoingMessages removeObjectAtIndex:0];
            lastActivity = [NSDate new];
            [ioHandler send:data fileDescriptor:descriptor];
        }
        dataRead = [ioHandler readBytes:36 fileDescriptor:descriptor];
        lastActivity = [NSDate new];
    } @catch (IOException *exception) {
        [self unsafeClose];
        stateChanged = true;
    }
    [resourceLock unlock];
    if (dataRead) {
        [_delegate connection:self chunkHasArrived:dataRead];
    }
    if (stateChanged) {
        [_delegate connection:self stateHasChanged:state];
    }
}
@end

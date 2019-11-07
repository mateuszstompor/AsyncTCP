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
    NSMutableData * buffer;
    NSLock * resourceLock;
    struct sockaddr_in address;
    socklen_t addressLength;
    ConnectionState state;
    ssize_t chunkSize;
    NSObject<IONetworkHandleable>* ioHandler;
    NSMutableArray<NSData*>* outgoingMessages;
    NSObject<NetworkManageable>* networkManager;
    dispatch_queue_t notificationQueue;
}
@end

@implementation Connection
@synthesize delegate=_delegate;
-(instancetype) initWithAddress: (struct sockaddr_in) address
                  addressLength: (socklen_t) addressLength
                     descriptor: (int) descriptor
                      chunkSize: (ssize_t) chunkSize
              notificationQueue: (dispatch_queue_t) notificationQueue
                      ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
                 networkManager: (NSObject<NetworkManageable>*) networkManager {
    self = [super init];
    if (self) {
        self->descriptor = descriptor;
        self->address = address;
        self->ioHandler = ioHandler;
        self->addressLength = addressLength;
        self->resourceLock = [NSLock new];
        self->lastActivity = [NSDate new];
        self->buffer = [NSMutableData new];
        self->chunkSize = chunkSize;
        self->notificationQueue = notificationQueue;
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
-(void)close {
    BOOL notifyDelegate = NO;
    [resourceLock lock];
    if(state != closed) {
        notifyDelegate = YES;
        [self unsafeClose];
    }
    [resourceLock unlock];
    __weak Connection * weakSelf = self;
    if (weakSelf == nil || notifyDelegate == NO) {
        return;
    }
    dispatch_async(notificationQueue, ^{
        [weakSelf.delegate connection:weakSelf stateHasChangedTo:weakSelf.state];
    });
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
    NSData * dataToSent = nil;
    BOOL stateChanged = NO;
    @try {
        if ([outgoingMessages count] > 0) {
            NSData * data = [outgoingMessages objectAtIndex:0];
            [outgoingMessages removeObjectAtIndex:0];
            lastActivity = [NSDate new];
            [ioHandler send:data fileDescriptor:descriptor];
        }
        NSData * dataRead = [ioHandler readBytes:chunkSize fileDescriptor:descriptor];
        if(dataRead) {
            lastActivity = [NSDate new];
            [buffer appendData:dataRead];
            if([buffer length] >= chunkSize) {
                dataToSent = [buffer subdataWithRange:NSMakeRange(0, chunkSize)];
                buffer = [[buffer subdataWithRange:NSMakeRange(chunkSize, [buffer length] - chunkSize)] mutableCopy];
            }
        }
    } @catch (IOException *exception) {
        [self unsafeClose];
        stateChanged = YES;
    }
    [resourceLock unlock];
    __weak Connection * weakSelf = self;
    if (weakSelf == nil) {
        return;
    }
    if (dataToSent) {
        dispatch_async(notificationQueue, ^{
            [weakSelf.delegate connection:weakSelf chunkHasArrived:dataToSent];
        });
    }
    if (stateChanged) {
        dispatch_async(notificationQueue, ^{
            [weakSelf.delegate connection:weakSelf stateHasChangedTo:weakSelf.state];
        });
    }
}
@end

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

#import "Exceptions.h"
#import "ResourceLock.h"
#import "NetworkManager.h"
#import "NetworkWrapper.h"
#import "IONetworkHandler.h"
#import "ConnectionDelegate.h"


@interface Connection()
{
    ssize_t chunkSize;
    ssize_t readErrorsInRow;
    ssize_t writeErrorsInRow;
    Identity * identity;
    NSDate* lastActivity;
    NSMutableData* buffer;
    ConnectionState state;
    NSObject<Lockable>* resourceLock;
    NSMutableArray<NSData*>* outgoingMessages;
    NSObject<NetworkManageable>* networkManager;
}
@property (atomic, nonnull) NSObject<Dispatchable>* notificationQueue;
@end

@implementation Connection
@synthesize delegate=_delegate;
@synthesize notificationQueue=_notificationQueue;
-(instancetype)initWithIdentity: (Identity*) identity
                      chunkSize: (ssize_t) chunkSize
              notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                 networkManager: (NSObject<NetworkManageable>*) networkManager
                   resourceLock: (NSObject<Lockable>*) resourceLock {
    self = [super init];
    if (self) {
        self->identity = identity;
        self->resourceLock = resourceLock;
        self->lastActivity = [NSDate new];
        self->buffer = [NSMutableData new];
        self->chunkSize = chunkSize;
        self->state = active;
        self->networkManager = networkManager;
        self->outgoingMessages = [NSMutableArray new];
        self->writeErrorsInRow = 0;
        self->readErrorsInRow = 0;
        self.notificationQueue = notificationQueue;
    }
    return self;
}
-(BOOL)enqueueDataForSending: (NSData*) data {
    [resourceLock aquireLock];
    if (state == active) {
        [outgoingMessages addObject:data];
        [resourceLock releaseLock];
        return YES;
    } else {
        [resourceLock releaseLock];
        return NO;
    }
}
-(void)close {
    [resourceLock aquireLock];
    if(state != closed) {
        [self unsafeClose];
    }
    [resourceLock releaseLock];
}
-(void)unsafeClose {
    state = closed;
    [networkManager close:identity];
}
-(ConnectionState)state {
    [resourceLock aquireLock];
    ConnectionState stateToReturn = state;
    [resourceLock releaseLock];
    return stateToReturn;
}
-(NSTimeInterval)lastInteractionInterval {
    [resourceLock aquireLock];
    NSTimeInterval interval = [[NSDate new] timeIntervalSinceDate:lastActivity];
    [resourceLock releaseLock];
    return interval;
}
-(NSData*)buffer {
    [resourceLock aquireLock];
    NSData* currentBuffer = [buffer copy];
    [resourceLock releaseLock];
    return currentBuffer;
}
-(void)send {
    [resourceLock aquireLock];
    if ([outgoingMessages count] > 0) {
        NSData * data = [outgoingMessages objectAtIndex:0];
        NSData * dataLeft = nil;
        @try {
            dataLeft = [networkManager send:data identity:identity];
            writeErrorsInRow = 0;
        } @catch (IOException * exception) {
            writeErrorsInRow += 1;
            [resourceLock releaseLock];
            return;
        }
        lastActivity = [NSDate new];
        [outgoingMessages removeObjectAtIndex:0];
        if (dataLeft) {
            [outgoingMessages insertObject:dataLeft atIndex:0];
        }
    }
    [resourceLock releaseLock];
}
-(void)read {
    NSData * dataRead = nil;
    NSData * dataToSent = nil;
    [resourceLock aquireLock];
    @try {
        dataRead = [networkManager readBytes:chunkSize identity:identity];
        readErrorsInRow = 0;
    } @catch (IOException * exception) {
        readErrorsInRow += 1;
        [resourceLock releaseLock];
        return;
    }
    if(dataRead) {
        lastActivity = [NSDate new];
        [buffer appendData:dataRead];
        if([buffer length] >= chunkSize) {
            dataToSent = [buffer subdataWithRange:NSMakeRange(0, chunkSize)];
            buffer = [[buffer subdataWithRange:NSMakeRange(chunkSize, [buffer length] - chunkSize)] mutableCopy];
        }
    }
    [resourceLock releaseLock];
    __weak Connection * weakSelf = self;
    if (dataToSent) {
        [self.notificationQueue async:^{
            [weakSelf.delegate connection:weakSelf chunkHasArrived:dataToSent];
        }];
    }
}
-(void)performIO {
    [self send];
    [self read];
}
-(ssize_t)totalErrorsInRow {
    ssize_t total;
    [resourceLock aquireLock];
    total = writeErrorsInRow + readErrorsInRow;
    [resourceLock releaseLock];
    return total;
}
-(BOOL)isClosed {
    [resourceLock aquireLock];
    BOOL is = state == closed;
    [resourceLock releaseLock];
    return is;
}
@end

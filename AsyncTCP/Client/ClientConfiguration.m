//
//  ClientConfiguration.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ClientConfiguration.h"

@implementation ClientConfiguration
-(instancetype)initWithAddress: (NSString *) address
                          port: (int) port
                     chunkSize: (ssize_t) chunkSize
             connectionTimeout: (useconds_t) connectionTimeout
    eventLoopMicrosecondsDelay: (useconds_t) eventLoopMicrosecondsDelay
 errorsBeforeConnectionClosing: (ssize_t) errorsBeforeConnectionClosing {
    self = [super init];
    if (self) {
        self.address = address;
        self.port = port;
        self.chunkSize = chunkSize;
        self.connectionTimeout = connectionTimeout;
        self.eventLoopMicrosecondsDelay = eventLoopMicrosecondsDelay;
        self.errorsBeforeConnectionClosing = errorsBeforeConnectionClosing;
    }
    return self;
}
@end

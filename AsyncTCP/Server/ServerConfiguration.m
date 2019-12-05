//
//  ServerConfiguration.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ServerConfiguration.h"

@implementation ServerConfiguration
-(instancetype)initWithPort: (int) port
    maximalConnectionsCount: (int) maximalConnectionsCount
                  chunkSize: (ssize_t) chunkSize
          connectionTimeout: (useconds_t) connectionTimeout
 eventLoopMicrosecondsDelay: (useconds_t) eventLoopMicrosecondsDelay
errorsBeforeConnectionClosing: (ssize_t) errorsBeforeConnectionClosing {
    self = [super init];
    if (self) {
        self.port = port;
        self.maximalConnectionsCount = maximalConnectionsCount;
        self.chunkSize = chunkSize;
        self.connectionTimeout = connectionTimeout;
        self.eventLoopMicrosecondsDelay = eventLoopMicrosecondsDelay;
        self.errorsBeforeConnectionClosing = errorsBeforeConnectionClosing;
    }
    return self;
}
@end

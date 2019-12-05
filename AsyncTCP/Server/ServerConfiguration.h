//
//  ServerConfiguration.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ServerConfiguration: NSObject
@property (nonatomic) int port;
@property (nonatomic) int maximalConnectionsCount;
@property (nonatomic) ssize_t chunkSize;
@property (nonatomic) useconds_t connectionTimeout;
@property (nonatomic) useconds_t eventLoopMicrosecondsDelay;
@property (nonatomic) ssize_t errorsBeforeConnectionClosing;
-(instancetype)initWithPort: (int) port
    maximalConnectionsCount: (int) maximalConnectionsCount
                  chunkSize: (ssize_t) chunkSize
          connectionTimeout: (useconds_t) connectionTimeout
 eventLoopMicrosecondsDelay: (useconds_t) eventLoopMicrosecondsDelay
errorsBeforeConnectionClosing: (ssize_t) errorsBeforeConnectionClosing;
@end

NS_ASSUME_NONNULL_END

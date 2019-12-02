//
//  ServerConfiguration.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct ServerConfiguration {
    int port;
    int maximalConnectionsCount;
    ssize_t chunkSize;
    useconds_t connectionTimeout;
    useconds_t eventLoopMicrosecondsDelay;
    ssize_t errorsBeforeConnectionClosing;
};

NS_ASSUME_NONNULL_END

//
//  ClientConfiguration.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct ClientConfiguration {
    const char * address;
    int port;
    ssize_t chunkSize;
    useconds_t connectionTimeout;
    useconds_t eventLoopMicrosecondsDelay;
};

NS_ASSUME_NONNULL_END

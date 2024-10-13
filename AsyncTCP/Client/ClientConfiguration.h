//
//  ClientConfiguration.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sys/types.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClientConfiguration: NSObject
@property (nonatomic) NSString * address;
@property (nonatomic) int port;
@property (nonatomic) ssize_t chunkSize;
@property (nonatomic) useconds_t connectionTimeout;
@property (nonatomic) useconds_t eventLoopMicrosecondsDelay;
@property (nonatomic) ssize_t errorsBeforeConnectionClosing;
-(instancetype)initWithAddress: (NSString *) address
                          port: (int) port
                     chunkSize: (ssize_t) chunkSize
             connectionTimeout: (useconds_t) connectionTimeout
    eventLoopMicrosecondsDelay: (useconds_t) eventLoopMicrosecondsDelay
 errorsBeforeConnectionClosing: (ssize_t) errorsBeforeConnectionClosing;   
@end

NS_ASSUME_NONNULL_END

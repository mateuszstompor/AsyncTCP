//
//  ServerHandler.h
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Server.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ConnectionDelegate;

@interface ServerHandler: NSObject<ServerDelegate>
-(instancetype)init;
-(instancetype)initWithConnectionHandler: (nullable NSObject<ConnectionDelegate>*) connectionHandler;
@property (atomic, nullable) NSObject<ConnectionHandle> * lastConnection;
@property (atomic, nullable) NSObject<ConnectionDelegate> * connectionHandler;
@end

NS_ASSUME_NONNULL_END

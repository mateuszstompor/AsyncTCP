//
//  Server.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Connection.h"
#import "ServerHandle.h"
#import "NetworkWrappable.h"
#import "ServerConfiguration.h"
#import "IONetworkHandleable.h"
#import "SocketOptionsWrapper.h"
#import "DescriptorControlWrappable.h"

NS_ASSUME_NONNULL_BEGIN

@interface Server: NSObject<ServerHandle>
@property (atomic, readonly) struct ServerConfiguration configuration;
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration;
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue;
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager;
@end

NS_ASSUME_NONNULL_END

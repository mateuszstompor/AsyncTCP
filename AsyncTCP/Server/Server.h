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
                           ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
                      networkManager: (NSObject<NetworkManageable>*) networkManager
            descriptorControlWrapper: (NSObject<DescriptorControlWrappable>*) descriptorControlWrapper
                socketOptionsWrapper: (NSObject<SocketOptionsWrappable>*) socketOptionsWrapper
                      networkWrapper: (NSObject<NetworkWrappable>*) networkWrapper;
@end

NS_ASSUME_NONNULL_END

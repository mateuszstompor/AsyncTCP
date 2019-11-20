//
//  Server.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Lockable.h"
#import "Connection.h"
#import "Dispatchable.h"
#import "ServerHandle.h"
#import "ThreadProducible.h"
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
                   notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager
                        resourceLock: (NSObject<Lockable>*) resourceLock
                       threadFactory: (NSObject<ThreadProducible>*) threadFactory;
@end

NS_ASSUME_NONNULL_END

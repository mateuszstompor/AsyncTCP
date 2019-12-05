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
#import "LockProducible.h"
#import "SystemWrappable.h"
#import "ThreadProducible.h"
#import "ServerConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface Server: NSObject<ServerHandle>
@property (atomic, readonly) ServerConfiguration * configuration;
-(instancetype)initWithConfiguratoin: (ServerConfiguration *) configuration;
-(instancetype)initWithConfiguratoin: (ServerConfiguration *) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue;
-(instancetype)initWithConfiguratoin: (ServerConfiguration *) configuration
                   notificationQueue: (NSObject<Dispatchable> *) notificationQueue
                      networkManager: (NSObject<NetworkManageable> *) networkManager
                       threadFactory: (NSObject<ThreadProducible> *) threadFactory
                         lockFactory: (NSObject<LockProducible> *) lockFactory
                       systemWrapper: (NSObject<SystemWrappable> *) systemWrapper;
@end

NS_ASSUME_NONNULL_END

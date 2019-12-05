//
//  Client.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Lockable.h"
#import "Threadable.h"
#import "Dispatchable.h"
#import "ClientHandle.h"
#import "LockProducible.h"
#import "SystemWrappable.h"
#import "ThreadProducible.h"
#import "NetworkManageable.h"
#import "ClientConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface Client: NSObject<ClientHandle>
@property (atomic, readonly) ClientConfiguration * configuration;
@property (nullable, atomic) NSObject<ClientDelegate> * delegate;
-(instancetype)initWithConfiguration: (ClientConfiguration *) configuration;
-(instancetype)initWithConfiguration: (ClientConfiguration *) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue;
-(instancetype)initWithConfiguration: (ClientConfiguration *) configuration
                   notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager
                         lockFactory: (NSObject<LockProducible>*) lockFactory
                       threadFactory: (NSObject<ThreadProducible>*) threadFactory
                       systemWrapper: (NSObject<SystemWrappable> *) systemWrapper;
@end

NS_ASSUME_NONNULL_END

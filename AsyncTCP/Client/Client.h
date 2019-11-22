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
#import "NetworkManager.h"
#import "ThreadProducible.h"
#import "NetworkWrappable.h"
#import "ClientConfiguration.h"
#import "IONetworkHandleable.h"
#import "SocketOptionsWrappable.h"
#import "DescriptorControlWrappable.h"

NS_ASSUME_NONNULL_BEGIN

@interface Client: NSObject<ClientHandle>
@property (atomic, readonly) struct ClientConfiguration configuration;
@property (nullable, atomic) NSObject<ClientDelegate> * delegate;
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration;
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue;
-(instancetype)initWithConfiguration: (struct ClientConfiguration) configuration
                   notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                      networkManager: (NSObject<NetworkManageable>*) networkManager
                         lockFactory: (NSObject<LockProducible>*) lockFactory
                       threadFactory: (NSObject<ThreadProducible>*) threadFactory;
@end

NS_ASSUME_NONNULL_END

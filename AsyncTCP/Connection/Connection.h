//
//  Connection.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Lockable.h"
#import "Identity.h"
#import "Dispatchable.h"
#import "ConnectionState.h"
#import "ConnectionHandle.h"
#import "NetworkWrappable.h"
#import "NetworkManageable.h"
#import "IONetworkHandleable.h"

NS_ASSUME_NONNULL_BEGIN

@interface Connection: NSObject<ConnectionHandle>
-(instancetype)initWithIdentity: (Identity*) identity
                      chunkSize: (ssize_t) chunkSize
              notificationQueue: (NSObject<Dispatchable>*) notificationQueue
                 networkManager: (NSObject<NetworkManageable>*) networkManager
                   resourceLock: (NSObject<Lockable>*) resourceLock;
-(NSTimeInterval)lastInteractionInterval;
-(BOOL)isClosed;
-(void)performIO;
@end

NS_ASSUME_NONNULL_END

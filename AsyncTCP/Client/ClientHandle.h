//
//  ClientHandle.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ClientDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ClientHandle<NSObject>
@required
@property (atomic, readonly) struct ClientConfiguration configuration;
@property (nullable, atomic) NSObject<ClientDelegate> * delegate;
-(void)boot;
-(BOOL)isRunning;
-(void)shutDown: (BOOL) waitForClientThread;
@end

NS_ASSUME_NONNULL_END

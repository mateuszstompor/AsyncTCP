//
//  ClientHandle.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ClientConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ClientHandle<NSObject>
@required
@property (atomic, readonly) struct ClientConfiguration configuration;
-(void)boot;
-(BOOL)isRunning;
-(void)shutDown;
@end

NS_ASSUME_NONNULL_END

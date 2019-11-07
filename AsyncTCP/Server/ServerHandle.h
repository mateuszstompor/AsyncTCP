//
//  ServerHandle.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ServerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ServerHandle<NSObject>
@property (atomic, nullable) NSObject<ServerDelegate>* delegate;
-(void)boot;
-(BOOL)isRunning;
-(void)shutDown;
-(NSInteger)connectedClientsCount;
-(struct ServerConfiguration)configuration;
@end

NS_ASSUME_NONNULL_END

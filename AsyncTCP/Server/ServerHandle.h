//
//  ServerHandle.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ServerDelegate.h"
#import "ServerConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ServerHandle<NSObject>
@required
@property (atomic, readonly) ServerConfiguration * configuration;
@property (atomic, nullable, weak) NSObject<ServerDelegate>* delegate;
-(void)boot;
-(BOOL)isRunning;
-(void)shutDown: (BOOL) waitForServerThread;
-(NSInteger)connectedClientsCount;
@end

NS_ASSUME_NONNULL_END

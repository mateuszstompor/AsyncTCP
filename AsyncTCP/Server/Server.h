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
#import "ServerConfiguration.h"
#import "IONetworkHandleable.h"
#import "FileDescriptorConfigurable.h"

NS_ASSUME_NONNULL_BEGIN

@interface BootingException : NSException
@end

@interface ShuttingDownException : NSException
@end

@interface Server: NSObject<ServerHandle>
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration
                   notificationQueue: (dispatch_queue_t) notificationQueue
                           ioHandler: (NSObject<IONetworkHandleable>*) ioHandler
          fileDescriptorConfigurator: (NSObject<FileDescriptorConfigurable>*) fileDescriptorConfigurator
                      networkManager: (NSObject<NetworkManageable>*) networkManager;
-(instancetype)initWithConfiguratoin: (struct ServerConfiguration) configuration;
@end

NS_ASSUME_NONNULL_END

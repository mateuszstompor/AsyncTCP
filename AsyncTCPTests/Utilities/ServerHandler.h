//
//  ServerHandler.h
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Server.h"

NS_ASSUME_NONNULL_BEGIN

@interface ServerHandler: NSObject<ServerDelegate>
@property (atomic, nullable) Connection * lastConnection;
@end

NS_ASSUME_NONNULL_END

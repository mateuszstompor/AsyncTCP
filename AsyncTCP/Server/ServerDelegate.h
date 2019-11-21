//
//  ServerDelegate.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ConnectionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class Connection;

@protocol ServerDelegate <NSObject>
-(void)newClientHasConnected: (Connection*) connection;
-(void)clientHasDisconnected: (Connection*) connection;
@end

NS_ASSUME_NONNULL_END

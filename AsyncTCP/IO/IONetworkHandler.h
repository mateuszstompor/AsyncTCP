//
//  IONetworkHandler.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NetworkWrappable.h"
#import "IONetworkHandleable.h"

NS_ASSUME_NONNULL_BEGIN

@interface IONetworkHandler: NSObject<IONetworkHandleable>
-(instancetype)initWithWrapper: (NSObject<NetworkWrappable>*) networkWrapper;
@end

NS_ASSUME_NONNULL_END

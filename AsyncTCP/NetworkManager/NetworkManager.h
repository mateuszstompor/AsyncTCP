//
//  NetworkManager.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NetworkWrappable.h"
#import "NetworkManageable.h"
#import "IONetworkHandleable.h"
#import "SocketOptionsWrappable.h"
#import "DescriptorControlWrappable.h"

NS_ASSUME_NONNULL_BEGIN

@interface NetworkManager: NSObject<NetworkManageable>
-(instancetype)initWithSocketOptionsWrapper: (NSObject<SocketOptionsWrappable>*) socketOptionsWrapper
                   descriptorControlWrapper: (NSObject<DescriptorControlWrappable>*) descriptorControlWrapper
                             networkWrapper: (NSObject<NetworkWrappable>*) networkWrapper
                           ioNetworkHandler: (NSObject<IONetworkHandleable>*) ioNetworkHandler;
@end

NS_ASSUME_NONNULL_END

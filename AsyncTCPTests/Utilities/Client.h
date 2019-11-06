//
//  Client.h
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Client : NSObject
@property (atomic) int descriptor;
-(instancetype)initWithHost: (const char *)hostname port: (int) port;
-(int)connect;
-(int)close;
@end

NS_ASSUME_NONNULL_END

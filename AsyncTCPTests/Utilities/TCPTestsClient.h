//
//  TCPTestsClient.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCPTestsClient : NSObject
@property (atomic) int descriptor;
-(instancetype)initWithHost: (const char *)hostname port: (int) port;
-(int)connect;
-(ssize_t)send: (char *) data length: (size_t) length;
-(ssize_t)readToBuffer: (void *) buffer size: (size_t) size;
-(int)close;
@end

NS_ASSUME_NONNULL_END

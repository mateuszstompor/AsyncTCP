//
//  NetworkWrappable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NetworkWrappable<NSObject>
-(int)socket;
-(int)close: (int) fileDescriptor;
-(int)bind: (int) descriptor withAddress: (struct sockaddr *) address length: (socklen_t) length;
-(int)accept: (int) descriptor withAddress: (struct sockaddr *) address length: (socklen_t *) length;
-(int)connect: (int) descriptor withAddress: (struct sockaddr const *) address length: (socklen_t) length;
-(int)listen: (int) descriptor maximalConnectionsCount: (int) maximalConnectionsCount;
-(ssize_t)send: (int) descriptor buffer: (const void *) buffer size: (size_t) size flags: (int) flags;
-(ssize_t)receive: (int) descirptor buffer: (void *) buffer size: (size_t) size flags: (int) flags;
-(int)errnoValue;
@end

NS_ASSUME_NONNULL_END

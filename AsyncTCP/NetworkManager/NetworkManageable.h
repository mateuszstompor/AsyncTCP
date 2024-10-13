//
//  NetworkManageable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sys/types.h>

#import "Identity.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NetworkManageable<NSObject>
@required
-(BOOL)isValidAndHealthy: (Identity *) identity;
-(struct sockaddr_in)localServerIdentityWithPort: (int) port;
-(struct sockaddr_in)identityWithAddress: (in_addr_t) address withPort: (int) port;
-(struct sockaddr_in)identityWithHost: (NSString*) host withPort: (int) port;
-(BOOL)hasPortValidRange: (int) port;
-(BOOL)close: (Identity *) identity;
-(nullable NSData*)send: (NSData*) data identity: (Identity*) identity;
-(NSData*)readBytes: (ssize_t) amount identity: (Identity*) identity;
-(Identity*)acceptNewIdentity: (Identity*) serverIdentity;
-(Identity*)localIdentityOnPort: (int) port maximalConnectionsCount: (int) maximalConnectionsCount;
-(Identity*)clientIdentityToHost: (NSString*) host withPort: (int) port;
-(BOOL)connect: (Identity*) identity;
@end

NS_ASSUME_NONNULL_END

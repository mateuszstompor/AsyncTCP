//
//  NetworkManageable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NetworkManageable<NSObject>
@required
-(BOOL)isValidOpenFileDescriptor: (int) fileDescriptor;
-(struct sockaddr_in)localServerIdentityWithPort: (int) port;
-(struct sockaddr_in)identityWithAddress: (in_addr_t) address withPort: (int) port;
-(struct sockaddr_in)identityWithHost: (NSString*) host withPort: (int) port;
-(BOOL)close: (int) fileDescriptor;
-(BOOL)hasPortValidRange: (int) port;
@end

NS_ASSUME_NONNULL_END

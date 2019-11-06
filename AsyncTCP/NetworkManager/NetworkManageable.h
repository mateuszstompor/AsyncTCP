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
-(BOOL)isValidOpenFileDescriptor: (int) fileDescriptor;
-(struct sockaddr_in)localServerAddressWithPort: (int) port;
-(BOOL)close: (int) fileDescriptor;
-(BOOL)isPortInRange: (int) port;
@end

NS_ASSUME_NONNULL_END

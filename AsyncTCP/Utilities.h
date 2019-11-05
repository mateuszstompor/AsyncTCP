//
//  Utilities.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utilities : NSObject
+(BOOL)isPortInRange: (int) port;
+(struct sockaddr_in)localServerAddressWithPort: (int) port;
+(BOOL)makeNonBlocking: (int) fileDescriptor;
+(BOOL)noSigPipe: (int) fileDescriptor;
+(BOOL)isValidOpenFileDescriptor: (int) fileDescriptor;
+(BOOL)reuseAddress: (int) fileDescriptor;
+(BOOL)close: (int) fileDescriptor;
@end

NS_ASSUME_NONNULL_END

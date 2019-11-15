//
//  IONetworkHandleable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface IOException: NSException
@end

@protocol IONetworkHandleable<NSObject>
-(BOOL)send: (NSData*) data fileDescriptor: (int) fileDescriptor;
-(NSData*)readBytes: (ssize_t) amount fileDescriptor: (int) fileDescriptor;
@end

NS_ASSUME_NONNULL_END

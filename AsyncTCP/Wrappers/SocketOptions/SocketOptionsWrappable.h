//
//  SocketOptionsWrappable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol SocketOptionsWrappable<NSObject>
-(int)noSigPipe: (int) fileDescriptor;
-(int)reuseAddress:(int) fileDescriptor;
-(int)reusePort: (int) fileDescriptor;
@end

NS_ASSUME_NONNULL_END

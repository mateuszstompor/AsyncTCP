//
//  FileDescriptorConfigurable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FileDescriptorConfigurable<NSObject>
-(BOOL)makeNonBlocking: (int) fileDescriptor;
-(BOOL)noSigPipe: (int) fileDescriptor;
-(BOOL)isValidOpenFileDescriptor: (int) fileDescriptor;
-(BOOL)reuseAddress: (int) fileDescriptor;
@end

NS_ASSUME_NONNULL_END

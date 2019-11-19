//
//  DescriptorControlWrappable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DescriptorControlWrappable<NSObject>
@required
-(int)makeNonBlocking: (int) fileDescriptor;
-(int)descriptorStatus: (int) fileDescriptor;
@end

NS_ASSUME_NONNULL_END

//
//  SystemWrappable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SystemWrappable
-(int)waitMicroseconds: (useconds_t) microseconds;
@end

NS_ASSUME_NONNULL_END

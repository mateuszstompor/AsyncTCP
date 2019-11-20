//
//  Thread.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Threadable.h"

NS_ASSUME_NONNULL_BEGIN

@interface Thread: NSObject<Threadable>
-(instancetype)initWithTarget:(id)target selector:(SEL)selector object:(nullable id)argument;
@end

NS_ASSUME_NONNULL_END

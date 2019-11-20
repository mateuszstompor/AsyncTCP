//
//  ThreadFactory.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ThreadProducible.h"

NS_ASSUME_NONNULL_BEGIN

@interface ThreadFactory: NSObject<ThreadProducible>
@end

NS_ASSUME_NONNULL_END

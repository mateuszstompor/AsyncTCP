//
//  ResourceLockFactory.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 22/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LockProducible.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResourceLockFactory: NSObject<LockProducible>
@end

NS_ASSUME_NONNULL_END

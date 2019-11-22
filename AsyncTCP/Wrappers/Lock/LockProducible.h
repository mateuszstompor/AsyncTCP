//
//  LockProducible.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 22/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Lockable.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LockProducible<NSObject>
-(NSObject<Lockable>*)newLock;
@end

NS_ASSUME_NONNULL_END

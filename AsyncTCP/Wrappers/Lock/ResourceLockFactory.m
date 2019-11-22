//
//  ResourceLockFactory.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 22/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ResourceLockFactory.h"

#import "ResourceLock.h"

@implementation ResourceLockFactory
-(nonnull NSObject<Lockable> *)newLock {
    return [ResourceLock new];
}
@end

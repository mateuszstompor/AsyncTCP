//
//  ResourceLock.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ResourceLock.h"

@interface ResourceLock()
{
    NSLock * lock;
}
@end

@implementation ResourceLock
-(instancetype)init {
    self = [super init];
    if (self) {
        lock = [NSLock new];
    }
    return self;
}
-(void)aquireLock {
    [lock lock];
}
-(void)releaseLock {
    [lock unlock];
}
@end

//
//  Dispatch.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Dispatch.h"

@interface Dispatch()
{
    dispatch_queue_t dispatchQueue;
}
@end

@implementation Dispatch
-(instancetype)init {
    return [self initWithDispatchQueue:dispatch_get_main_queue()];
}
-(instancetype)initWithDispatchQueue: (dispatch_queue_t) dispatchQueue {
    self = [super init];
    if (self) {
        self->dispatchQueue = dispatchQueue;
    }
    return self;
}
-(void)async:(dispatch_block_t)block {
    dispatch_async(dispatchQueue, block);
}
@end

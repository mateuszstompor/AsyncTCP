//
//  TasksGroup.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 21/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "TasksGroup.h"

@interface TasksGroup()
{
    dispatch_group_t group;
}
@end

@implementation TasksGroup
-(instancetype)init {
    self = [super init];
    if (self) {
        group = dispatch_group_create();
    }
    return self;
}
-(void)enter {
    dispatch_group_enter(group);
}
- (void)leave {
    dispatch_group_leave(group);
}
- (void)waitForever {
    dispatch_wait(group, DISPATCH_TIME_FOREVER);
}
@end

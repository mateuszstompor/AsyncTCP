//
//  Thread.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Thread.h"

@interface Thread()
{
    NSThread * thread;
}
@end

@implementation Thread
@synthesize name;
-(instancetype)initWithTarget:(id)target selector:(SEL)selector object:(nullable id)argument {
    self = [super init];
    if (self) {
        thread = [[NSThread alloc] initWithTarget:target selector:selector object:argument];
    }
    return self;
}
-(void)start {
    [thread start];
}
-(void)cancel {
    [thread cancel];
}
-(BOOL)isExecuting {
    return [thread isExecuting];
}
-(BOOL)isCancelled {
    return [thread isCancelled];
}
-(void)setName:(NSString *)name {
    [thread setName:name];
}
@end

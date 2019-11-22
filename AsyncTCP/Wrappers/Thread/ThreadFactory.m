//
//  ThreadFactory.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ThreadFactory.h"
#import "Thread.h"

@implementation ThreadFactory
-(NSObject<Threadable>*)createNewThreadWithTarget:(id)target
                                         selector:(SEL)selector
                                             name:(NSString*)name {
    Thread * thread = [[Thread alloc] initWithTarget:target selector:selector object:nil];
    thread.name = name;
    return thread;
}
@end

//
//  CountingThreadFactory.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 04/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "CountingThreadFactory.h"

@implementation CountingThreadFactory
-(NSObject<Threadable> *)createNewThreadWithTarget:(id)target selector:(SEL)selector name: (NSString *) name {
    id newThread = [super createNewThreadWithTarget:target selector:selector name: name];
    _instancesCreated += 1;
    return newThread;
}
@end

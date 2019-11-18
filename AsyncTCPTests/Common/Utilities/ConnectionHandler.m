//
//  ConnectionHandler.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 07/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ConnectionHandler.h"

@implementation ConnectionHandler
- (instancetype)init {
    self = [super init];
    if (self) {
        self.data = [NSMutableArray new];
    }
    return self;
}
-(void)connection:(NSObject<ConnectionHandle> *)connection chunkHasArrived:(NSData *)data {
    [self.data addObject:data];
}
-(void)connection:(NSObject<ConnectionHandle> *)connection stateHasChangedTo:(ConnectionState)state {
}
@end

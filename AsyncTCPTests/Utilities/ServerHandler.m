//
//  ServerHandler.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ServerHandler.h"

@implementation ServerHandler
- (instancetype)init {
    self = [super init];
    if (self) {
        self.lastConnection = nil;
    }
    return self;
}
-(void)newClientHasConnected: (Connection*) connection {
    [self setLastConnection:connection];
}
@end

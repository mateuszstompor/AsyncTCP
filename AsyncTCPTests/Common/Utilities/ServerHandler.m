//
//  ServerHandler.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "ServerHandler.h"

@implementation ServerHandler
-(instancetype)init {
    self = [self initWithConnectionHandler:nil];
    return self;
}
-(instancetype)initWithConnectionHandler: (NSObject<ConnectionDelegate>*) connectionHandler {
    self = [super init];
    if (self) {
        self.lastConnection = nil;
        self.connectionHandler = connectionHandler;
    }
    return self;
}
-(void)newClientHasConnected: (Connection*) connection {
    connection.delegate = self.connectionHandler;
    [self setLastConnection:connection];
}
@end

//
//  BootingProblemsTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 22/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface BootingProblemsTests : XCTestCase
{
    Server * server;
    struct ServerConfiguration configuration;
}
@end

@implementation BootingProblemsTests
-(void)setUp {
    configuration.port = 8091;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 5;
    configuration.chunkSize = 10;
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testBootingTwoServerOnTheSamePort {
    Server * serverB = [[Server alloc] initWithConfiguratoin: configuration];
    [server boot];
    @try {
        [serverB boot];
    } @catch (BootingException * exception) {
        XCTFail("Booting should not raise exception if the same port is used");
    }
    [serverB shutDown:YES];
    [server shutDown:YES];
}
@end

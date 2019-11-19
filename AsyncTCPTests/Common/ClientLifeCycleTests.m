//
//  ClientLifeCycleTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 15/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ClientLifeCycleTests: XCTestCase
{
    Client * client;
}
@end

@implementation ClientLifeCycleTests
-(void)setUp {
    struct ClientConfiguration configuration;
    configuration.address = "localhost";
    configuration.chunkSize = 30;
    configuration.port = 45870;
    configuration.eventLoopMicrosecondsDelay = 400;
    configuration.connectionTimeout = 5;
    client = [[Client alloc] initWithConfiguration:configuration];
}
-(void)testBooting {
    XCTAssertFalse([client isRunning]);
    [client boot];
    usleep(100);
    XCTAssertTrue([client isRunning]);
    [client shutDown];
    XCTAssertFalse([client isRunning]);
}
@end

//
//  LifeCycleTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>
#import <netdb.h>

#import "Utilities/TestsClient.h"

@interface LifeCycleTests: XCTestCase
{
    NSObject<ServerHandle> * asyncServer;
    struct ServerConfiguration configuration;
}
@end

@implementation LifeCycleTests
-(void)setUp {
    configuration.port = 47851;
    configuration.chunkSize = 36;
    configuration.connectionTimeout = 5;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 0;
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testBootAndShutdown {
    [asyncServer boot];
    usleep(100);
    XCTAssertTrue([asyncServer isRunning]);
    [asyncServer boot];
    XCTAssertTrue([asyncServer isRunning]);
    [asyncServer shutDown];
    usleep(100);
    XCTAssertFalse([asyncServer isRunning]);
}
@end

//
//  LifeCycleTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <netdb.h>

#import "Server.h"
#import "NetworkManager.h"
#import "Utilities/Client.h"
#import "IONetworkHandler.h"
#import "ServerConfiguration.h"
#import "FileDescriptorConfigurator.h"

@interface LifeCycleTests: XCTestCase
{
    Server * asyncServer;
    struct ServerConfiguration configuration;
}
@end

@implementation LifeCycleTests
-(void)setUp {
    configuration.port = 47851;
    configuration.chunkSize = 36;
    configuration.connectionTimeout = 5;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 400;
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testBootAndShutdown {
    [asyncServer boot];
    usleep(50);
    XCTAssertTrue([asyncServer isRunning]);
    [asyncServer boot];
    XCTAssertTrue([asyncServer isRunning]);
    [asyncServer shutDown];
    sleep(2);
    XCTAssertFalse([asyncServer isRunning]);
}
@end

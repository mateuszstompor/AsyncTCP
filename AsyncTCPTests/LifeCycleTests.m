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

@interface LifeCycleTests : XCTestCase
{
    Client * client;
    Server * asyncServer;
    struct ServerConfiguration configuration;
}
@end

@implementation LifeCycleTests
-(void)setUp {
    configuration.port = 47850;
    configuration.chunkSize = 36;
    configuration.connectionTimeout = 5;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 400;
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration];
    client = [[Client alloc] initWithHost:"localhost" port:47850];
}
-(void)testBootAndShutdown {
    [asyncServer boot];
    if ([client connect] < 0) {
        XCTFail("Port is closed");
    }
    [asyncServer shutDown];
    if ([client connect] >= 0) {
        XCTFail("Port is not closed");
    }
    XCTAssertEqual([client close], 0);
    [asyncServer boot];
    if ([client connect] < 0) {
        XCTFail("Port is closed");
    }
    XCTAssertEqual([client close], 0);
    [asyncServer shutDown];
    if ([client connect] >= 0) {
        XCTFail("Port is not closed");
    }
    XCTAssertEqual([client close], 0);
}
@end

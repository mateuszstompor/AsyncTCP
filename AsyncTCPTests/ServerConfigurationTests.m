//
//  ServerConfigurationTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 17/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ServerConfigurationTests : XCTestCase
{
    Server * server;
}
@end

@implementation ServerConfigurationTests
-(void)setUp {
    struct ServerConfiguration configuration;
    configuration.port = 57880;
    configuration.maximalConnectionsCount = 5;
    configuration.eventLoopMicrosecondsDelay = 40;
    configuration.connectionTimeout = 4;
    configuration.chunkSize = 40;
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testConfiguration {
    XCTAssertEqual([server configuration].chunkSize, 40);
    XCTAssertEqual([server configuration].connectionTimeout, 4);
    XCTAssertEqual([server configuration].eventLoopMicrosecondsDelay, 40);
    XCTAssertEqual([server configuration].maximalConnectionsCount, 5);
    XCTAssertEqual([server configuration].port, 57880);
}
@end

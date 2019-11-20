//
//  ClientConfigurationTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 17/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ClientConfigurationTests : XCTestCase
{
    Client * client;
}
@end

@implementation ClientConfigurationTests
-(void)setUp {
    struct ClientConfiguration configuration;
    configuration.port = 57800;
    configuration.address = "localhost";
    configuration.chunkSize = 30;
    configuration.connectionTimeout = 5;
    configuration.eventLoopMicrosecondsDelay = 40;
    client = [[Client alloc] initWithConfiguration:configuration];
}
-(void)testConfiguration {
    XCTAssertEqual(strcmp([client configuration].address, "localhost"), 0);
    XCTAssertEqual([client configuration].port, 57800);
    XCTAssertEqual([client configuration].chunkSize, 30);
    XCTAssertEqual([client configuration].connectionTimeout, 5);
    XCTAssertEqual([client configuration].eventLoopMicrosecondsDelay, 40);
}
@end

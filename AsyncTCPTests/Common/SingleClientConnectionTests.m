//
//  SingleClientConnectionTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <netdb.h>
#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "TestsClient.h"
#import "ServerHandler.h"

@interface SingleClientConnectionTests: XCTestCase
{
    TestsClient * client;
    TestsClient * anotherClient;
    NSObject<ServerHandle> * asyncServer;
    ServerHandler * handler;
    struct ServerConfiguration configuration;
}
@end

@implementation SingleClientConnectionTests
-(void)setUp {
    handler = [[ServerHandler alloc] init];
    configuration.port = 47853;
    configuration.chunkSize = 36;
    configuration.connectionTimeout = 1;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 0;
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration
                                      notificationQueue:dispatch_get_global_queue(0, 0)];
    client = [[TestsClient alloc] initWithHost:"localhost" port:47853];
    anotherClient = [[TestsClient alloc] initWithHost:"localhost" port:47853];
}
-(void)testOneClient {
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
-(void)testSecondClientConnectingWhileOneIsConnected {
    asyncServer.delegate = handler;
    XCTAssertEqual([asyncServer connectedClientsCount], 0);
    [asyncServer boot];
    XCTAssertEqual([client connect], 0);
    usleep(100);
    XCTAssertEqual([asyncServer connectedClientsCount], 1);
    [asyncServer shutDown];
    XCTAssertEqual([asyncServer connectedClientsCount], 0);
}
-(void)testTimeout {
    asyncServer.delegate = handler;
    XCTAssertEqual([asyncServer connectedClientsCount], 0);
    [asyncServer boot];
    XCTAssertEqual([client connect], 0);
    usleep(100);
    XCTAssertEqual([asyncServer connectedClientsCount], 1);
    sleep(2);
    XCTAssertEqual([asyncServer connectedClientsCount], 0);
    [asyncServer shutDown];
}
@end
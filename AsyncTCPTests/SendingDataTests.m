//
//  SendingDataTests.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 07/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Server.h"
#import "TestsClient.h"
#import "Utilities/ServerHandler.h"
#import "Utilities/ConnectionHandler.h"

@interface SendingDataTests: XCTestCase
{
    NSObject<ServerHandle> * asyncServer;
    ServerHandler * serverHandler;
    ConnectionHandler * connectionHandler;
    struct ServerConfiguration configuration;
    TestsClient * client;
}
@end

@implementation SendingDataTests
-(void)setUp {
    configuration.port = 47856;
    configuration.chunkSize = 2;
    configuration.connectionTimeout = 5;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 0;
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration
                                      notificationQueue:dispatch_get_global_queue(0, 0)];
    connectionHandler = [[ConnectionHandler alloc] init];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionHandler];
    client = [[TestsClient alloc] initWithHost:"localhost" port:47856];
    asyncServer.delegate = serverHandler;
}
-(void)testSendManyChunks {
    [asyncServer boot];
    [client connect];
    for(int i=0; i<10; ++i) {
        XCTAssertEqual([client send:"a" length:1], 1);
        usleep(100);
        XCTAssertEqual([connectionHandler.data count], 0);
        XCTAssertEqual([client send:"b" length:1], 1);
        usleep(100);
        XCTAssertEqual([connectionHandler.data count], 1);
        XCTAssertEqual(strcmp([[connectionHandler.data objectAtIndex:0] bytes], "ab"), 0);
        [connectionHandler.data removeAllObjects];
    }
    [asyncServer shutDown];
}
-(void)testWholeChunkAtOnce {
    [asyncServer boot];
    [client connect];
    for(int i=0; i<10; ++i) {
        XCTAssertEqual([connectionHandler.data count], 0);
        XCTAssertEqual([client send:"ab" length:2], 2);
        usleep(100);
        XCTAssertEqual(strcmp([[connectionHandler.data objectAtIndex:0] bytes], "ab"), 0);
        [connectionHandler.data removeAllObjects];
    }
    [asyncServer shutDown];
}
@end

//
//  ReceivingConnectionEventsTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//


#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "TCPTestsClient.h"

@interface ConnectionEventsHandler: NSObject<ConnectionDelegate>
{
    XCTestExpectation * connectionStateChangedExpectation;
    XCTestExpectation * dataReceivedExpectation;
}
-(instancetype)initWithConnectionStateHasChangedExpectation: (XCTestExpectation*) connectionStateExpectation
                                    dataReceivedExpectation: (XCTestExpectation*) dataReceivedExpectation;
@end

@implementation ConnectionEventsHandler
-(instancetype)initWithConnectionStateHasChangedExpectation: (XCTestExpectation*) connectionStateChangedExpectation
                                    dataReceivedExpectation: (XCTestExpectation*) dataReceivedExpectation {
    self = [super init];
    if (self) {
        self->connectionStateChangedExpectation = connectionStateChangedExpectation;
        self->dataReceivedExpectation = dataReceivedExpectation;
    }
    return self;
}
-(void)connection:(NSObject<ConnectionHandle> *)connection chunkHasArrived:(NSData *)data {
    [dataReceivedExpectation fulfill];
}
-(void)connection:(NSObject<ConnectionHandle> *)connection stateHasChangedTo:(ConnectionState)state {
    [connectionStateChangedExpectation fulfill];
}
@end

@interface ServerHandler: NSObject<ServerDelegate>
{
    NSObject<ConnectionDelegate>* connectionHandler;
}
-(instancetype)initWithConnectionHandler: (NSObject<ConnectionDelegate>*) connectionHandler;
@end

@implementation ServerHandler
-(instancetype)initWithConnectionHandler: (NSObject<ConnectionDelegate>*) connectionHandler {
    self = [super init];
    if (self) {
        self->connectionHandler = connectionHandler;
    }
    return self;
}
-(void)newClientHasConnected: (Connection *)connection {
    connection.delegate = connectionHandler;
}
@end

@interface ReceivingConnectionEventsTests : XCTestCase
{
    Server * server;
    ServerHandler * serverHandler;
    ConnectionEventsHandler * connectionEventsHandler;
}
@end

@implementation ReceivingConnectionEventsTests
-(void)setUp {
    struct ServerConfiguration configuration;
    configuration.port = 8091;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 5;
    configuration.chunkSize = 10;
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testNoCallbackIsReceivedWhenNothingHappens {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * connectionStateHasChanged = [[XCTestExpectation alloc]
                                                     initWithDescription:@"Callback informing about connection state change"];
    XCTestExpectation * dataHasBeenReceived = [[XCTestExpectation alloc]
                                               initWithDescription:@"Callback informing about incoming data"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc] initWithConnectionStateHasChangedExpectation:connectionStateHasChanged
                                                                                    dataReceivedExpectation:dataHasBeenReceived];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler];
    server.delegate = serverHandler;
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [dataHasBeenReceived setInverted:YES];
    [connectionStateHasChanged setInverted:YES];
    [self waitForExpectations:@[connectionStateHasChanged, dataHasBeenReceived] timeout:3];
    [client close];
    [server shutDown];
}
-(void)testCallbackIsReceivedWhenClientDisconnects {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * connectionStateHasChanged = [[XCTestExpectation alloc]
                                                     initWithDescription:@"Callback informing about connection state change"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc] initWithConnectionStateHasChangedExpectation:connectionStateHasChanged
                                                                                    dataReceivedExpectation:nil];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler];
    server.delegate = serverHandler;
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client close];
    [self waitForExpectations:@[connectionStateHasChanged] timeout:7];
    [server shutDown];
}
-(void)testCallbackIsReceivedWhenDataIsSent {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * dataHasBeenReceived = [[XCTestExpectation alloc]
                                               initWithDescription:@"Callback informing about incoming data"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc] initWithConnectionStateHasChangedExpectation:nil
                                                                                    dataReceivedExpectation:dataHasBeenReceived];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler];
    server.delegate = serverHandler;
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client send:"hello" length:10];
    [self waitForExpectations:@[dataHasBeenReceived] timeout:6];
    XCTAssertEqual([dataHasBeenReceived expectedFulfillmentCount], 1);
    [client close];
    [server shutDown];
}
@end


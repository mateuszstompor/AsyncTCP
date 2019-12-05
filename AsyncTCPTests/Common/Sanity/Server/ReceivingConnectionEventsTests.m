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
    XCTestExpectation * dataReceivedExpectation;
}
-(instancetype)initWithDataReceivedExpectation: (XCTestExpectation*) dataReceivedExpectation;
@end

@implementation ConnectionEventsHandler
-(instancetype)initWithDataReceivedExpectation: (XCTestExpectation*) dataReceivedExpectation {
    self = [super init];
    if (self) {
        self->dataReceivedExpectation = dataReceivedExpectation;
    }
    return self;
}
-(void)connection:(NSObject<ConnectionHandle> *)connection chunkHasArrived:(NSData *)data {
    [dataReceivedExpectation fulfill];
}
@end

@interface ServerHandler: NSObject<ServerDelegate>
{
    XCTestExpectation * clientConnectedExpectation;
    XCTestExpectation * clientDisconnectedExpectation;
    NSObject<ConnectionDelegate>* connectionHandler;
}
@property (atomic) Connection * connection;
-(instancetype)initWithConnectionHandler: (NSObject<ConnectionDelegate>*) connectionHandler
              clientConnectedExpectation: (XCTestExpectation *) clientConnectedExpectation
           clientDisconnectedExpectation: (XCTestExpectation *) clientDisconnectedExpectation;
@end

@implementation ServerHandler
-(instancetype)initWithConnectionHandler: (NSObject<ConnectionDelegate>*) connectionHandler
              clientConnectedExpectation: (XCTestExpectation *) clientConnectedExpectation
           clientDisconnectedExpectation: (XCTestExpectation *) clientDisconnectedExpectation {
    self = [super init];
    if (self) {
        self->connectionHandler = connectionHandler;
        self->clientConnectedExpectation = clientConnectedExpectation;
        self->clientDisconnectedExpectation = clientDisconnectedExpectation;
    }
    return self;
}
-(void)newClientHasConnected: (Connection *)connection {
    [clientConnectedExpectation fulfill];
    self.connection = connection;
    self.connection.delegate = connectionHandler;
}
-(void)clientHasDisconnected:(Connection *)connection {
    [clientDisconnectedExpectation fulfill];
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
    ServerConfiguration * configuration = [[ServerConfiguration alloc] initWithPort:8091
                                                            maximalConnectionsCount:1
                                                                          chunkSize:10
                                                                  connectionTimeout:5
                                                         eventLoopMicrosecondsDelay:10
                                                      errorsBeforeConnectionClosing:3];
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)testNoCallbackIsReceivedWhenNothingHappens {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * connectionStateHasChanged = [[XCTestExpectation alloc]
                                                     initWithDescription:@"Callback informing about connection state change"];
    XCTestExpectation * dataHasBeenReceived = [[XCTestExpectation alloc]
                                               initWithDescription:@"Callback informing about incoming data"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc] initWithDataReceivedExpectation:dataHasBeenReceived];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler
                                          clientConnectedExpectation:nil
                                       clientDisconnectedExpectation:connectionStateHasChanged];
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
    [server shutDown:YES];
}
-(void)testCallbackIsReceivedWhenClientDisconnects {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * connectionStateHasChanged = [[XCTestExpectation alloc]
                                                     initWithDescription:@"Callback informing about connection state change"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc] initWithDataReceivedExpectation:nil];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler
                                          clientConnectedExpectation:nil
                                       clientDisconnectedExpectation:connectionStateHasChanged];
    server.delegate = serverHandler;
    [server boot];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:[NSPredicate predicateWithFormat:@"connect >= 0"]
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client close];
    [self waitForExpectations:@[connectionStateHasChanged] timeout:10];
    [server shutDown:YES];
}
-(void)testCallbackIsReceivedWhenDataIsSent {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * dataHasBeenReceived = [[XCTestExpectation alloc]
                                               initWithDescription:@"Callback informing about incoming data"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc] initWithDataReceivedExpectation:dataHasBeenReceived];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler
                                          clientConnectedExpectation:nil
                                       clientDisconnectedExpectation:nil];
    server.delegate = serverHandler;
    [server boot];
    NSPredicate * clientHasConnectedPredicate = [NSPredicate predicateWithFormat:@"connect >= 0"];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:clientHasConnectedPredicate
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client send:"hellohello" length:10];
    [self waitForExpectations:@[dataHasBeenReceived] timeout:6];
    XCTAssertEqual([dataHasBeenReceived expectedFulfillmentCount], 1);
    [client close];
    [server shutDown:YES];
}
-(void)testCallbackIsNotReceivedPartialDataIsSent {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * dataHasBeenReceived = [[XCTestExpectation alloc]
                                               initWithDescription:@"Callback informing about incoming data"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc]
                               initWithDataReceivedExpectation:dataHasBeenReceived];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler
                                          clientConnectedExpectation:nil
                                       clientDisconnectedExpectation:nil];
    server.delegate = serverHandler;
    [server boot];
    NSPredicate * clientHasConnectedPredicate = [NSPredicate predicateWithFormat:@"connect >= 0"];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:clientHasConnectedPredicate
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [dataHasBeenReceived setInverted:YES];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client send:"hellohell" length:9];
    [self waitForExpectations:@[dataHasBeenReceived] timeout:6];
    [client send:"o" length:1];
    [client close];
    [server shutDown:YES];
}
-(void)testCallbackIsReceivedWhenFullDataIsSentPartially {
    TCPTestsClient * client = [[TCPTestsClient alloc] initWithHost:"localhost" port:8091];
    XCTestExpectation * dataHasBeenReceived = [[XCTestExpectation alloc]
                                               initWithDescription:@"Callback informing about incoming data"];
    connectionEventsHandler = [[ConnectionEventsHandler alloc] initWithDataReceivedExpectation:dataHasBeenReceived];
    serverHandler = [[ServerHandler alloc] initWithConnectionHandler:connectionEventsHandler
                                          clientConnectedExpectation:nil
                                       clientDisconnectedExpectation:nil];
    server.delegate = serverHandler;
    [server boot];
    NSPredicate * clientHasConnectedPredicate = [NSPredicate predicateWithFormat:@"connect >= 0"];
    XCTestExpectation * clientHasConnected = [self expectationForPredicate:clientHasConnectedPredicate
                                                       evaluatedWithObject:client
                                                                   handler:nil];
    [self waitForExpectations:@[clientHasConnected] timeout:3];
    [client send:"hellohell" length:9];
    [client send:"hellohell" length:9];
    [self waitForExpectations:@[dataHasBeenReceived] timeout:6];
    XCTAssertEqual([dataHasBeenReceived expectedFulfillmentCount], 1);
    [client close];
    [server shutDown:YES];
}
@end


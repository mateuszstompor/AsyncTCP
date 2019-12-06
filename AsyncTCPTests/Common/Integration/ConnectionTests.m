//
//  ConnectionTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 22/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface ConnectionClientHandler: NSObject<ClientDelegate>
{
    XCTestExpectation * connectionEstablished;
    XCTestExpectation * connectionClosed;
}
-(instancetype)initWithConnectionEstablishedExpectation: (XCTestExpectation *) connectionEstablished
                                       connectionClosed: (XCTestExpectation *) connectionClosed;
@end

@implementation ConnectionClientHandler
-(instancetype)initWithConnectionEstablishedExpectation: (XCTestExpectation *) connectionEstablished
                                       connectionClosed: (XCTestExpectation *) connectionClosed {
    self = [super init];
    if (self) {
        self->connectionEstablished = connectionEstablished;
        self->connectionClosed = connectionClosed;
        
    }
    return self;
}
-(void)connectionHasBeenEstablished:(Connection *)connection {
    [connectionEstablished fulfill];
}
-(void)connectionHasBeenClosed:(Connection *)connection {
    [connectionClosed fulfill];
}
@end

@interface ConnectionServerHandler: NSObject<ServerDelegate>
{
    XCTestExpectation * connectionEstablished;
    XCTestExpectation * connectionBroken;
}
-(instancetype)initWithConnectionEstablished: (XCTestExpectation *) connectionEstablished
                            connectionBroken: (XCTestExpectation *) connectionBroken;
@end

@implementation ConnectionServerHandler
-(instancetype)initWithConnectionEstablished: (XCTestExpectation *) connectionEstablished
                            connectionBroken: (XCTestExpectation *) connectionBroken {
    self = [super init];
    if (self) {
        self->connectionEstablished = connectionEstablished;
        self->connectionBroken = connectionBroken;
    }
    return self;
}
-(void)clientHasDisconnected:(nonnull Connection *)connection {
    [connectionBroken fulfill];
}

-(void)newClientHasConnected:(nonnull Connection *)connection {
    [connectionEstablished fulfill];
}
@end

@interface SendingDataFromClient : XCTestCase
{
    Client * client;
    Server * server;
}
@end

@implementation SendingDataFromClient
-(void)setUpServer {
    ServerConfiguration * configuration = [[ServerConfiguration alloc] initWithPort:8090
                                                            maximalConnectionsCount:1
                                                                          chunkSize:10
                                                                  connectionTimeout:5
                                                         eventLoopMicrosecondsDelay:10
                                                      errorsBeforeConnectionClosing:3];
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)setUpClient {
    ClientConfiguration * configuration = [[ClientConfiguration alloc] initWithAddress:@"127.0.0.1"
                                                                                  port:8090
                                                                             chunkSize:10
                                                                     connectionTimeout:10
                                                            eventLoopMicrosecondsDelay:10
                                                         errorsBeforeConnectionClosing:3];
    client = [[Client alloc] initWithConfiguration:configuration];
}
-(void)setUp {
    [self setUpServer];
    [self setUpClient];
}
-(void)testConnectionEstablishing {
    XCTestExpectation * clientHasEstablishedConnection = [[XCTestExpectation alloc] initWithDescription:@"Client has established connection"];
    XCTestExpectation * clientHasLostConnection = [[XCTestExpectation alloc] initWithDescription:@"Client has lost the connection"];
    ConnectionClientHandler * clientHandler = [[ConnectionClientHandler alloc] initWithConnectionEstablishedExpectation:clientHasEstablishedConnection
                                                                                                       connectionClosed:clientHasLostConnection];
    XCTestExpectation * serverHasEstablishedConnection = [[XCTestExpectation alloc] initWithDescription:@"Server has established connection with client"];
    XCTestExpectation * serverHasLostConnection = [[XCTestExpectation alloc] initWithDescription:@"Server has lost the connection"];
    ConnectionServerHandler * serverHandler = [[ConnectionServerHandler alloc] initWithConnectionEstablished:serverHasEstablishedConnection
                                                                                            connectionBroken:serverHasLostConnection];
    server.delegate = serverHandler;
    client.delegate = clientHandler;
    [server boot];
    [client boot];
    [self waitForExpectations:@[clientHasEstablishedConnection,
                                serverHasEstablishedConnection] timeout:10];
    [client shutDown: YES];
    [server shutDown:YES];
    [self waitForExpectations:@[serverHasLostConnection] timeout:10];
}
-(void)testClosingConnectionWhenClientGoesDown {
    XCTestExpectation * clientHasEstablishedConnection = [XCTestExpectation new];
    XCTestExpectation * clientHasLostConnection = [XCTestExpectation new];
    ConnectionClientHandler * clientHandler = [[ConnectionClientHandler alloc] initWithConnectionEstablishedExpectation:clientHasEstablishedConnection
                                                                                                       connectionClosed:clientHasLostConnection];
    XCTestExpectation * serverHasEstablishedConnection = [XCTestExpectation new];
    XCTestExpectation * serverHasLostConnection = [XCTestExpectation new];
    ConnectionServerHandler * serverHandler = [[ConnectionServerHandler alloc] initWithConnectionEstablished:serverHasEstablishedConnection
                                                                                            connectionBroken:serverHasLostConnection];
    server.delegate = serverHandler;
    client.delegate = clientHandler;
    [server boot];
    [client boot];
    [self waitForExpectations:@[clientHasEstablishedConnection,
                                serverHasEstablishedConnection]
                      timeout:10];
    [client shutDown: NO];
    [self waitForExpectations: @[clientHasLostConnection, serverHasLostConnection]
                      timeout:10];
    [server shutDown: NO];
}
-(void)testClosingConnectionWhenServerGoesDown {
    XCTestExpectation * clientHasEstablishedConnection = [XCTestExpectation new];
    XCTestExpectation * clientHasLostConnection = [XCTestExpectation new];
    ConnectionClientHandler * clientHandler = [[ConnectionClientHandler alloc] initWithConnectionEstablishedExpectation:clientHasEstablishedConnection
                                                                                                       connectionClosed:clientHasLostConnection];
    XCTestExpectation * serverHasEstablishedConnection = [XCTestExpectation new];
    XCTestExpectation * serverHasLostConnection = [XCTestExpectation new];
    ConnectionServerHandler * serverHandler = [[ConnectionServerHandler alloc] initWithConnectionEstablished:serverHasEstablishedConnection
                                                                                            connectionBroken:serverHasLostConnection];
    server.delegate = serverHandler;
    client.delegate = clientHandler;
    [server boot];
    [client boot];
    [self waitForExpectations:@[clientHasEstablishedConnection,
                                serverHasEstablishedConnection] timeout:10];
    [server shutDown: NO];
    [self waitForExpectations: @[clientHasLostConnection,
                                 serverHasLostConnection] timeout:10];
    [client shutDown: NO];
}
-(void)testClientReconnectingWhenServerGoesUpAndDown {
    XCTestExpectation * clientHasEstablishedConnection = [XCTestExpectation new];
    XCTestExpectation * clientHasLostConnection = [XCTestExpectation new];
    XCTestExpectation * serverHasEstablishedConnection = [XCTestExpectation new];
    [clientHasEstablishedConnection setExpectedFulfillmentCount:2];
    [clientHasLostConnection setAssertForOverFulfill:YES];
    ConnectionClientHandler * clientHandler = [[ConnectionClientHandler alloc] initWithConnectionEstablishedExpectation:clientHasEstablishedConnection
                                                                                                       connectionClosed:clientHasLostConnection];
    ConnectionServerHandler * serverHandler = [[ConnectionServerHandler alloc] initWithConnectionEstablished:serverHasEstablishedConnection
                                                                                            connectionBroken:nil];
    server.delegate = serverHandler;
    client.delegate = clientHandler;
    [server boot];
    [client boot];
    [self waitForExpectations:@[serverHasEstablishedConnection] timeout:10];
    sleep(5);
    [server shutDown: YES];
    [self waitForExpectations:@[clientHasLostConnection] timeout:10];
    [server boot];
    [self waitForExpectations:@[clientHasEstablishedConnection] timeout:25];
    [server shutDown:YES];
    [client shutDown:YES];
}
@end

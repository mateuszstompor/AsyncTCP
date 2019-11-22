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
    struct ServerConfiguration configuration;
    configuration.port = 8090;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 3;
    configuration.chunkSize = 10;
    server = [[Server alloc] initWithConfiguratoin:configuration];
}
-(void)setUpClient {
    struct ClientConfiguration configuration;
    configuration.address = "127.0.0.1";
    configuration.port = 8090;
    configuration.eventLoopMicrosecondsDelay = 10;
    configuration.connectionTimeout = 10;
    configuration.chunkSize = 10;
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
    [self waitForExpectations:@[clientHasEstablishedConnection, serverHasEstablishedConnection] timeout:10];
    [client shutDown];
    [server shutDown];
    [self waitForExpectations:@[serverHasLostConnection] timeout:10];
}
@end

//
//  CreatingLocalIdentityTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 04/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface FailingSocketCreatorNetworkWrapper: NetworkWrapper
{
    XCTestExpectation * socketCreated;
    XCTestExpectation * socketClosed;
}
-(instancetype)initWithSocketCreatedExpectation: (XCTestExpectation *) socketCreated
                                   socketClosed: (XCTestExpectation *) socketClosed;
@end

@implementation FailingSocketCreatorNetworkWrapper
-(instancetype)initWithSocketCreatedExpectation: (XCTestExpectation *) socketCreated
                                   socketClosed: (XCTestExpectation *) socketClosed {
    self = [super init];
    if (self) {
        self->socketCreated = socketCreated;
        self->socketClosed = socketClosed;
    }
    return self;
}
-(int)socket {
    [socketCreated fulfill];
    return -1;
}
-(int)close:(int)fileDescriptor {
    [socketClosed fulfill];
    return -1;
}
@end

@interface PassingSocketCreatorNetworkManager: NetworkWrapper
{
    XCTestExpectation * socketCreated;
    XCTestExpectation * socketClosed;
}
-(instancetype)initWithSocketCreatedExpectation: (XCTestExpectation *) socketCreated
                                   socketClosed: (XCTestExpectation *) socketClosed;
@end

@implementation PassingSocketCreatorNetworkManager
-(instancetype)initWithSocketCreatedExpectation: (XCTestExpectation *) socketCreated
                                   socketClosed: (XCTestExpectation *) socketClosed {
    self = [super init];
    if (self) {
        self->socketCreated = socketCreated;
        self->socketClosed = socketClosed;
    }
    return self;
}
-(int)socket {
    [socketCreated fulfill];
    return 150;
}
-(int)close:(int)fileDescriptor {
    [socketClosed fulfill];
    return 0;
}
@end

@interface NotReusableSocketOptionsWrapper: SocketOptionsWrapper
@end

@implementation NotReusableSocketOptionsWrapper
-(int)reuseAddress:(int)fileDescriptor {
    return -1;
}
@end

@interface CreatingLocalIdentityTests: XCTestCase
@end

@implementation CreatingLocalIdentityTests
-(void)testSocketCreationError {
    XCTestExpectation * socketCreated = [[XCTestExpectation alloc] initWithDescription:@"Socket Created"];
    XCTestExpectation * socketClosed = [[XCTestExpectation alloc] initWithDescription:@"Socket Closed"];
    NSObject<NetworkWrappable> * networkWrapper = [[FailingSocketCreatorNetworkWrapper alloc] initWithSocketCreatedExpectation:socketCreated
                                                                                                                  socketClosed:socketClosed];
    NSObject<NetworkManageable> * networkManager = [[NetworkManager alloc] initWithSocketOptionsWrapper:[SocketOptionsWrapper new]
                                                 descriptorControlWrapper:[DescriptorControlWrapper new]
                                                           networkWrapper:networkWrapper
                                                         ioNetworkHandler:[IONetworkHandler new]];
    @try {
        [socketClosed setInverted:YES];
        [networkManager localIdentityOnPort:8080 maximalConnectionsCount:1];
        XCTFail("Failure of socket creation should raise a IdentityCreationException");
    } @catch (IdentityCreationException * exception) {
        [self waitForExpectations:@[socketCreated, socketClosed] timeout:1];
    }
}
-(void)testReusingIdentityNotPossible {
    XCTestExpectation * socketCreated = [[XCTestExpectation alloc] initWithDescription:@"Socket Created"];
    XCTestExpectation * socketClosed = [[XCTestExpectation alloc] initWithDescription:@"Socket Closed"];
    NSObject<NetworkWrappable> * networkWrapper = [[PassingSocketCreatorNetworkManager alloc] initWithSocketCreatedExpectation:socketCreated
                                                                                                                  socketClosed:socketClosed];
    NSObject<NetworkManageable> * networkManager = [[NetworkManager alloc] initWithSocketOptionsWrapper:[SocketOptionsWrapper new]
                                                 descriptorControlWrapper:[DescriptorControlWrapper new]
                                                           networkWrapper:networkWrapper
                                                         ioNetworkHandler:[IONetworkHandler new]];
    @try {
        [networkManager localIdentityOnPort:1234 maximalConnectionsCount:1];
        XCTFail("Failure of socket creation should raise a IdentityCreationException");
    } @catch (IdentityCreationException * exception) {
        [self waitForExpectations:@[socketCreated, socketClosed] timeout:1];
    }
}
@end

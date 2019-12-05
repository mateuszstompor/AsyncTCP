//
//  IONetworkHandlerTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <AsyncTCP/AsyncTCP.h>

@interface PartialSendMock: NetworkWrapper
@end

@implementation PartialSendMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return 2;
}
-(int)errnoValue {
    return 0;
}
@end

@interface CompleteSendMock: NetworkWrapper
@end

@implementation CompleteSendMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return size;
}
-(ssize_t)receive:(int)descirptor buffer:(void *)buffer size:(size_t)size flags:(int)flags {
    const char * message = "success";
    ssize_t messageLength = 7;
    memcpy(buffer, message, messageLength);
    return messageLength;
}
-(int)errnoValue {
    return 0;
}
@end

@interface ResourceTemporarilyUnavailableMock: NetworkWrapper
@end

@implementation ResourceTemporarilyUnavailableMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(ssize_t)receive:(int)descirptor buffer:(void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(int)errnoValue {
    return EAGAIN;
}
@end

@interface OperationWouldBlockMock: NetworkWrapper
@end

@implementation OperationWouldBlockMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(ssize_t)receive:(int)descirptor buffer:(void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(int)errnoValue {
    return EWOULDBLOCK;
}
@end

@interface ConnectionResentWhileSendMock: NetworkWrapper
@end

@implementation ConnectionResentWhileSendMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(ssize_t)receive:(int)descirptor buffer:(void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(int)errnoValue {
    return ECONNRESET;
}
@end

@interface IONetworkHandlerTests : XCTestCase
@end

@implementation IONetworkHandlerTests
-(void)testPartialSend {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[PartialSendMock new]];
    NSData * result = [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
    XCTAssertNotNil(result);
    XCTAssertEqual([result length], 3);
    XCTAssertTrue([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] isEqualToString:@"llo"]);
}
-(void)testSuccessfulDataSending {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[CompleteSendMock new]];
    NSData * result = [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
    XCTAssertNil(result);
}
-(void)testSuccessfulDataReceiving {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[CompleteSendMock new]];
    NSData * result = [ioNetworkHandler readBytes: 20 fileDescriptor:2];
    XCTAssertNotNil(result);
    XCTAssertTrue([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] isEqualToString:@"success"]);
}
-(void)testWouldBlockWhileSendingData {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[OperationWouldBlockMock new]];
    NSData * result = [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
    XCTAssertTrue([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] isEqualToString:@"hello"]);
}
-(void)testWouldBlockWhileReceivingData {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[OperationWouldBlockMock new]];
    NSData * result = [ioNetworkHandler readBytes: 20 fileDescriptor:2];
    XCTAssertNil(result);
}
-(void)testResourceTemporarilyUnavailableWhileSendingData {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[ResourceTemporarilyUnavailableMock new]];
    NSData * result = [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
    XCTAssertTrue([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] isEqualToString:@"hello"]);
}
-(void)testResourceTemporarilyUnavailableWhileReceivingData {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[ResourceTemporarilyUnavailableMock new]];
    NSData * result = [ioNetworkHandler readBytes:10 fileDescriptor:2];
    XCTAssertNil(result);
}
-(void)testConnectionResetWhileSendingData {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[ConnectionResentWhileSendMock new]];
    @try {
        [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
        XCTFail("An exception should be raised");
    } @catch (IOException * exception) { }
}
-(void)testConnectionResetWhileReceivingData {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[ConnectionResentWhileSendMock new]];
    @try {
        [ioNetworkHandler readBytes:10 fileDescriptor:2];
        XCTFail("An exception should be raised");
    } @catch (IOException * exception) { }
}
@end

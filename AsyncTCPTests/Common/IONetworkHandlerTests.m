//
//  IONetworkHandlerTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <AsyncTCP/AsyncTCP.h>

@interface PartialSendMock: NSObject<NetworkWrappable>
@end

@implementation PartialSendMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return 2;
}
-(int)errnoValue {
    return 0;
}
@end

@interface CompleteSendMock: NSObject<NetworkWrappable>
@end

@implementation CompleteSendMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return size;
}
-(int)errnoValue {
    return 0;
}
@end

@interface ResourceTemporarilyUnavailableMock: NSObject<NetworkWrappable>
@end

@implementation ResourceTemporarilyUnavailableMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(int)errnoValue {
    return EAGAIN;
}
@end

@interface OperationWouldBlockMock: NSObject<NetworkWrappable>
@end

@implementation OperationWouldBlockMock
-(ssize_t)send:(int)descriptor buffer:(const void *)buffer size:(size_t)size flags:(int)flags {
    return -1;
}
-(int)errnoValue {
    return EWOULDBLOCK;
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
-(void)testCompleteSend {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[CompleteSendMock new]];
    NSData * result = [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
    XCTAssertNil(result);
}
-(void)testWouldBlock {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[OperationWouldBlockMock new]];
    NSData * result = [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
    XCTAssertTrue([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] isEqualToString:@"hello"]);
}
-(void)testResourceTemporarilyUnavailable {
    IONetworkHandler* ioNetworkHandler = [[IONetworkHandler alloc] initWithWrapper:[ResourceTemporarilyUnavailableMock new]];
    NSData * result = [ioNetworkHandler send:[@"hello" dataUsingEncoding:NSUTF8StringEncoding] fileDescriptor:2];
    XCTAssertTrue([[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] isEqualToString:@"hello"]);
}
@end

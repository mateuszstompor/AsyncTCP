//
//  Identity.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <netdb.h>
#import <sys/socket.h>

NS_ASSUME_NONNULL_BEGIN

@interface Identity: NSObject
@property (nonatomic) int descriptor;
@property (nonatomic) socklen_t addressLength;
@property (nonatomic) struct sockaddr_in address;
-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithDescriptor: (int) descriptor
                    addressLength: (socklen_t) addressLength
                          address: (struct sockaddr_in) address;
-(struct sockaddr_in *)addressPointer;
@end

NS_ASSUME_NONNULL_END

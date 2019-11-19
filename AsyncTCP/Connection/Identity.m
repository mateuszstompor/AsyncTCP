//
//  Identity.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Identity.h"

@implementation Identity
-(instancetype)init {
    self = [super init];
    if (self) {
        _descriptor = -1;
        _addressLength = 0;
        memset((void *)&_address, 0, sizeof(struct sockaddr_in));
    }
    return self;
}
-(instancetype)initWithDescriptor: (int) descriptor
                    addressLength: (socklen_t) addressLength
                          address: (struct sockaddr_in) address {
    self = [super init];
    if (self) {
        _descriptor = descriptor;
        _address = address;
        _addressLength = addressLength;
    }
    return self;
}
-(struct sockaddr_in *)addressPointer {
    return &_address;
}
@end

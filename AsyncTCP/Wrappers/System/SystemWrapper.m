//
//  SystemWrapper.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "SystemWrapper.h"

@implementation SystemWrapper
-(int)waitMicroseconds: (useconds_t) microseconds {
    return usleep(microseconds);
}
@end

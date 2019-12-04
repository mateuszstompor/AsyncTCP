//
//  CountingThreadFactory.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 04/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <AsyncTCP/AsyncTCP.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CountingThreadFactory: ThreadFactory
@property (atomic) int instancesCreated;
@end

NS_ASSUME_NONNULL_END

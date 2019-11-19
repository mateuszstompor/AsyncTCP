//
//  Lockable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol Lockable<NSObject>
-(void)aquireLock;
-(void)releaseLock;
@end

NS_ASSUME_NONNULL_END

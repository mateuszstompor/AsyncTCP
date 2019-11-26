//
//  Threadable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol Threadable<NSObject>
@property (nullable, copy) NSString * name;
@property (readonly, getter=isExecuting) BOOL executing;
@property (readonly, getter=isCancelled) BOOL cancelled;
-(void)start;
-(void)cancel;
@end

NS_ASSUME_NONNULL_END

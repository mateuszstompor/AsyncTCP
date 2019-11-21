//
//  TasksGroupable.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 21/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol TasksGroupable<NSObject>
-(void)enter;
-(void)leave;
-(void)waitForever;
@end

NS_ASSUME_NONNULL_END

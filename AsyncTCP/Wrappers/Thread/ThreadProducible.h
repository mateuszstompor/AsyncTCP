//
//  ThreadProducible.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 20/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Threadable.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ThreadProducible<NSObject>
-(NSObject<Threadable>*)createNewThreadWithTarget:(id)target
                                         selector:(SEL)selector
                                             name:(NSString*)name;
@end

NS_ASSUME_NONNULL_END

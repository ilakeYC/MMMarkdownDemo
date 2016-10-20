//
//  NSKeyValueObserver.h
//  markdownforwebviewtest
//
//  Created by LakesMac on 2016/10/20.
//  Copyright © 2016年 Dabllo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Block)(void);

@interface NSKeyValueObserver : NSObject


- (instancetype)init:(id)object
                 for:(NSString *)key
    didChangeHandler:(Block)handler;


@end

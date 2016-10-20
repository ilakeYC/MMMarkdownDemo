//
//  NSKeyValueObserver.m
//  markdownforwebviewtest
//
//  Created by LakesMac on 2016/10/20.
//  Copyright © 2016年 Dabllo. All rights reserved.
//

#import "NSKeyValueObserver.h"

@interface NSKeyValueObserver ()
{
    id  _object;
    NSString * _key;
    Block _privateHandler;
}

@end

@implementation NSKeyValueObserver

- (void)dealloc
{
    [_object removeObserver:self forKeyPath:_key];
}

- (instancetype)init:(id)object
                 for:(NSString *)key
    didChangeHandler:(Block)handler
{
    if (self = [super init]) {
        _object = object;
        _key = key;
        _privateHandler = handler;
        [_object addObserver:self forKeyPath:_key options:(NSKeyValueObservingOptionNew) context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([object isEqual:_object]) {
        _privateHandler();
    }
}

@end

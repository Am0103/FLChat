//
//  CustomUser.m
//  FLChat
//
//  Created by FL on 16/9/14.
//  Copyright © 2016年 zhigeng. All rights reserved.
//

#import "CustomUser.h"

@implementation CustomUser

- (id)initWithName:(NSString *)name avarUrl:(NSString *)avarUrl identify:(NSString *)identify
{
    self = [super init];
    if (self) {
        self.name = name;
        self.avarUrl = avarUrl;
        self.identify = identify;
    }
    return self;
}
@end

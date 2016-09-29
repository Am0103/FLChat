//
//  CustomUser.h
//  FLChat
//
//  Created by FL on 16/9/14.
//  Copyright © 2016年 zhigeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomUser : NSObject
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *avarUrl;
@property (nonatomic,copy) NSString *identify;

- (id)initWithName:(NSString *)name avarUrl:(NSString *)avarUrl identify:(NSString *)identify;
@end

//
//  SPSearchCell.m
//  FLChat
//
//  Created by FL on 16/9/20.
//  Copyright © 2016年 zhigeng. All rights reserved.
//

#import "SPSearchCell.h"

@implementation SPSearchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.backgroundColor = [UIColor redColor];
    NSLog(@"%f",self.frame.size.width);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

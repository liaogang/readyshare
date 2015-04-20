//
//  musicTableViewCell.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/20.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import "musicTableViewCell.h"

@interface musicTableViewCell ()


@end


@implementation musicTableViewCell

-(instancetype)initWithNib
{
    self = [super init];
    if (self) {
        self = [[NSBundle mainBundle]loadNibNamed:@"musicTableViewCell" owner:self options:nil][0];
        

    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

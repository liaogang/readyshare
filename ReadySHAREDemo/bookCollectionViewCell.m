//
//  bookCollectionViewCell.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/28.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import "bookCollectionViewCell.h"

@implementation bookCollectionViewCell
-(void)awakeFromNib
{
    self.selectedBackgroundView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"default_book_cover_set"]];
}
@end

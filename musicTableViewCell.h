//
//  musicTableViewCell.h
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/20.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface musicTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *textNumber;
@property (weak, nonatomic) IBOutlet UILabel *textName;

-(instancetype)initWithNib;

@end

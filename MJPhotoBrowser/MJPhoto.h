//
//  MJPhoto.h
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class KxSMBItemFile;

@interface MJPhoto : NSObject

//changed by lg
//@property (nonatomic, strong) NSURL *url;
@property (nonatomic , strong ) KxSMBItemFile *smbItem;

@property (nonatomic, strong) UIImage *image; // 完整的图片

@property (nonatomic, strong) UIImageView *srcImageView; // 来源view
//add by lg
@property (nonatomic  ) CGRect srcImageFrame;


@property (nonatomic ,strong) UIView * srcParentView;

@property (nonatomic, strong, readonly) UIImage *placeholder;
@property (nonatomic, strong, readonly) UIImage *capture;

@property (nonatomic, assign) BOOL firstShow;

// 是否已经保存到相册
@property (nonatomic, assign) BOOL save;
@property (nonatomic, assign) int index; // 索引
@end
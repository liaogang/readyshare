//
//  MainViewController.h
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

@end


@interface RootData : NSObject
+(instancetype)shared;

@property (nonatomic,strong) NSString * path;
@property (nonatomic,strong) NSString *userName,*passWord,*group;

@end

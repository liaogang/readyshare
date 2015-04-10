//
//  UIPopoverControllerBlock.h
//  ReadyShare
//
//  Created by liaogang on 5/22/14.
//  Copyright (c) 2014 gang.liao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIPopoverControllerBlock;

typedef void(^popOverControllerCallBack)(UIPopoverControllerBlock *popoverController,int index);


@interface UIPopoverControllerBlock : UIPopoverController
-(id)initWithObjects:(NSArray*)arr images:(NSArray*)arrImages CallBack:(popOverControllerCallBack)callback;
@end

//
//  sheettTableViewController.h
//  ReadyShare
//
//  Created by liaogang on 5/26/14.
//  Copyright (c) 2014 gang.liao. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^sheetTableViewCallBack)(NSArray *arrTableData);

@interface sheetTableViewController : UIViewController
-(id)initWithTitle:(NSString *)title detailTitle:(NSString*)detailTitle cancelBtn:(NSString*)cancel okBtn:(NSString*)ok datas:(NSArray*)datas images:(NSArray*)images placeHolders:(NSArray*)placeHolders dismissed:(sheetTableViewCallBack)callback;
-(void)show;
-(void)hide;
@end

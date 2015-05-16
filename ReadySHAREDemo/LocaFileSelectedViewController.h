//
//  LocaFileSelectedViewController.h
//  GenieiPad
//
//  Created by geine on 14-3-27.
//
//

#import <UIKit/UIKit.h>
#include<AssetsLibrary/AssetsLibrary.h>
#import <QuickLook/QuickLook.h>

#import "TreeViewController.h"

@interface LocaFileSelectedViewController : UIViewController<UIWebViewDelegate,QLPreviewControllerDataSource,UIGestureRecognizerDelegate>

@property (nonatomic, retain) UIImageView *imageView;

@property (nonatomic) CGRect defaultFrame;
@property (nonatomic, retain) NSMutableString *filePath;
@property (nonatomic, retain) NSMutableString *fileName;

@property (nonatomic, retain) NSMutableString *fileSize;

@property (nonatomic, retain) ALAssetsLibrary *library;
@property (nonatomic) BOOL is_libFile;
@property (nonatomic,retain) NSString *uploadPathForLibItems;

@property (nonatomic, retain)NSMutableArray *photosArray;
@property (nonatomic, retain)NSMutableArray *fileNameArray;
@property (nonatomic, retain)NSMutableArray *fileSizeArray;

@property (nonatomic, retain)NSString *documentDirectory;
@end

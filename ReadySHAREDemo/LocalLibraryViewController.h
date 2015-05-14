//
//  LocalLibraryViewController.h
//  GenieiPad
//
//  Created by geine on 14-3-27.
//
//

#import <UIKit/UIKit.h>
#include<AssetsLibrary/AssetsLibrary.h>

#import "UIImage+UIImageExt.h"
#import "LocaFileSelectedViewController.h"

@interface LocalLibraryViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    UITableView *lib_tableView;
    
    NSMutableArray *photoLB_fileArray;
    NSMutableArray *photoLB_sizeArray;
    NSMutableArray *photoLB_nameArray;
    NSMutableArray *photoLB_thumArray;
}

@property (nonatomic, retain) NSString *folderName;
@property (nonatomic, retain) ALAssetsLibrary *library;
@property (nonatomic) BOOL is_filterPic;

@property (nonatomic, retain) UIAlertView *loadAlertView;

- (id)initWithTag: (BOOL) is_pic;
@end

//
//  LocalViewController.h
//  GenieiPhoneiPod
//
//  Created by lixiang on 14-2-24.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetImageGenerator.h>
#import <AVFoundation/AVMetadataItem.h>
#include<AssetsLibrary/AssetsLibrary.h>

#import "LocalLibraryViewController.h"

@class TreeViewController;

@interface LocalViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    int m_rowCurr;                         //index of cell current selected
    NSMutableArray*     m_filesArray;
    NSMutableArray*     m_sizeArray;       //file size in dir
    UITableView*        m_tableView;
    NSString*           m_documentDirectory;
    NSFileManager*      m_fileManager;
    NSString*           m_fileName;
}

-(NSString*)GetFileNameCurrSel;
-(NSString*)GetDir;
-(NSFileManager*)GetFileManager;

@property(nonatomic,strong)  TreeViewController *remoteViewC;
@property (nonatomic,strong) UINavigationController *navController;
-(void)ReloadData;
-(void)showViewWithOrientation:(UIInterfaceOrientation)orientation;

@end

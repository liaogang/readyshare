//
//  MainViewController.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import "MainViewController.h"
#import "UIAlertViewBlock.h"
#import "ipTool.h"
#import "sheetTableViewController.h"
#import "RootData.h"
#import "TreeViewController.h"
#import "KxSMBProvider.h"

@interface MainViewController ()
<KxSMBProviderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnMovie;
@property (weak, nonatomic) IBOutlet UIButton *btnMusic;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnBook;

@end


@implementation MainViewController
#pragma mark - KxSMBProviderDelegate

- (KxSMBAuth *) smbAuthForServer: (NSString *) server
                       withShare: (NSString *) share
{
    RootData *s = [RootData shared];
    return [KxSMBAuth smbAuthWorkgroup:s.group username:s.userName password:s.passWord];
}

-(void)awakeFromNib
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ((KxSMBProvider*)[KxSMBProvider sharedSmbProvider]).delegate = self;
    
//    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithTitle:@"设置IP" style:UIBarButtonItemStyleDone target:self action:@selector(actionSetPath)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(figureOutRootPath)];
    

    
    [self figureOutRootPath];
    
    
    /*
    NSString *path = [RootData shared].path;
    if ( path == nil || path.length == 0) {
        [self performSelector:@selector(actionSetPath) withObject:nil afterDelay:0.3];
    }
    */
}

-(void)updateBtnState
{
    self.btnMovie.enabled=
    self.btnMusic.enabled=
    self.btnPhoto.enabled=
    self.btnBook.enabled=
    [self hasIpAddress];
}

-(bool)hasIpAddress
{
    return [RootData shared].path != nil;
}

-(void)figureOutRootPath
{
    [self updateBtnState];
    
    NSString *ipLocal = ipLocalHost();
    
    if (ipLocal)
    {
        char ip[20] ;
        
        strcpy( ip,  ipLocal.UTF8String );
        
        char *p = strrchr(ip, '.');
        
        strcpy( p + 1 , "1");
        
        ipLocal = [NSString stringWithUTF8String: ip];
        
        
        // get the root path.  192.168.x.x/xxx/Public
        
        NSString *rootPath = [NSString stringWithFormat:@"smb://%@",ipLocal];
        
        id result = [[KxSMBProvider sharedSmbProvider] fetchAtPath:rootPath];
        
        if([result isKindOfClass:[NSArray class]] && [result count] > 0 )
        {
            NSArray *arr = result;
            
            KxSMBItemTree *tree = arr.lastObject;
            
            // stringByAppendingPathComponent will remove a '/' in "//"
            rootPath = [ipLocal stringByAppendingPathComponent: tree.path.lastPathComponent];
            
            rootPath = [rootPath stringByAppendingPathComponent:@"Public"];
            
            rootPath = [NSString stringWithFormat:@"smb://%@",rootPath];
            // save
            [RootData shared].path = rootPath;
        }
        
        if ([result isKindOfClass:[NSError class]])
        {
            [self popupAuth];
        }
    }
    else
    {
        [[[UIAlertView alloc]initWithTitle:@"No ip address" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    
    [self updateBtnState];
}


-(void)actionSetPath
{
    UIAlertViewBlock *alert =    [[UIAlertViewBlock alloc] initWithTitle:@"设置IP" message:nil cancelButtonTitle:@"取消" cancelledBlock:nil okButtonTitles:@"设置" okBlock:^(UIAlertViewBlock *alert) {
        
        
        NSString *path = [alert textFieldAtIndex:0].text;
        
        [RootData shared].path = [NSString stringWithFormat:@"smb://%@",path];
        
        [self performSelector:@selector(popupAuth) withObject:nil afterDelay: 1];
    }];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    
    NSString *ipLocal = ipLocalHost();
    
    if (ipLocal)
    {
        char ip[20] ;
        
        strcpy( ip,  ipLocal.UTF8String );
        
        char *p = strrchr(ip, '.');
        
        strcpy( p + 1 , "1");
        
        ipLocal = [NSString stringWithUTF8String: ip];
        
        [alert textFieldAtIndex:0].placeholder = ipLocal ;
        [alert textFieldAtIndex:0].text = ipLocal ;
        
        [alert show];
    }
    else
    {
        [[[UIAlertView alloc]initWithTitle:@"No ip address" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    
}

-(void)popupAuth
{
    NSArray *datas=@[@"group",@"userName",@"password"];
    NSArray *placeH=@[@"workgroup",@"name",@"password"];
   
    
    // iPad 版本
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad )
    {
        sheetTableViewController *sheet=[[sheetTableViewController alloc]initWithTitle:@"认证信息" detailTitle:@"" cancelBtn:@"Cancel" okBtn:@"OK" datas:datas images:nil placeHolders:placeH dismissed:^(NSArray *arrTableData) {
            NSLog(@"%@",arrTableData);
            if(arrTableData)
            {
                [RootData shared].group = arrTableData[0];
                [RootData shared].userName = arrTableData[1];
                [RootData shared].passWord = arrTableData[2];
            }
        }];
        [sheet show];
    }
    // iPhone,iPod 版本
    else
    {
        UIAlertView *alert = [UIAlertView alloc];
        
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ( [sender isKindOfClass: [UIButton class]] )
    {
        UIButton *btn = sender;
        
        [RootData shared].currMediaType = btn.tag;
        
        TreeViewController *t = [segue destinationViewController];
        if ([t isKindOfClass:[TreeViewController class]])
        {
            t.mediaType = btn.tag;
            t.path = [RootData shared].path;
        }

        
    }
    
}


@end

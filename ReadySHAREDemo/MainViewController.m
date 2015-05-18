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

#import "MusicViewController.h"
#import "smbCollectionView.h"

#import "LocalViewController.h"

#import "CWPhotoViewerMasterViewController.h"

@interface UINavigationControllerMy : UINavigationController
-(BOOL)shouldAutorotate;
-(NSUInteger)supportedInterfaceOrientations;

@end

@implementation UINavigationControllerMy
/*
-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskLandscape;
}
 */


-(BOOL)shouldAutorotate
{
    return [[self.viewControllers lastObject] shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end

@interface MainViewController ()
<KxSMBProviderDelegate>
@property (weak, nonatomic) IBOutlet UIView *viewPortrait;
@property (weak, nonatomic) IBOutlet UIView *viewLanscape;

@property (weak, nonatomic) IBOutlet UIButton *btnMovie;
@property (weak, nonatomic) IBOutlet UIButton *btnMusic;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnBook;
@property (weak, nonatomic) IBOutlet UIButton *btnInternet;
@property (weak, nonatomic) IBOutlet UIButton *btnFileBrowse;

@property (weak, nonatomic) IBOutlet UIButton *btnMovie2;
@property (weak, nonatomic) IBOutlet UIButton *btnMusic2;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto2;
@property (weak, nonatomic) IBOutlet UIButton *btnBook2;
@property (weak, nonatomic) IBOutlet UIButton *btnInternet2;
@property (weak, nonatomic) IBOutlet UIButton *btnFileBrowse2;


@property (nonatomic,strong) NSString *ipRouter;

@property (nonatomic,strong) UIBarButtonItem *barReload;//*barAuth
@end


@implementation MainViewController
#pragma mark - KxSMBProviderDelegate

- (KxSMBAuth *) smbAuthForServer: (NSString *) server
                       withShare: (NSString *) share
{
    return [KxSMBAuth smbAuthWorkgroup:@"" username:@"admin" password:@"admin"];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    ((KxSMBProvider*)[KxSMBProvider sharedSmbProvider]).delegate = self;
    
    
    self.barReload = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(figureOutRootPath)];
    
    self.navigationItem.rightBarButtonItem =  self.barReload;


    
    [self figureOutRootPath];

}

#pragma mark - UIViewControllerRotation

-(void)viewWillAppear:(BOOL)animated
{
    // Iphone 下强制横屏
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if ( UIInterfaceOrientationIsPortrait (self.interfaceOrientation ) )
        {
            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }
    }
    
    // 测试使用版本到2015年7月1日
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"YYYY:MM:dd:hh:mm:ss"];
    NSString *date = [formatter stringFromDate:[NSDate date]];
    NSArray *array = [date componentsSeparatedByString:@":"];
    
    NSInteger year = [[array objectAtIndex:0] integerValue];
    NSInteger month = [[array objectAtIndex:1] integerValue];
    NSInteger day = [[array objectAtIndex:2] integerValue];
    NSInteger hour = [[array objectAtIndex:3] integerValue];
    NSInteger min = [[array objectAtIndex:4] integerValue];
    NSInteger sec = [[array objectAtIndex:5] integerValue];
    
    if(year == 2015 && month >=7 && day >=0 && hour >= 0 && min >= 0 && sec >= 0)
    {
        [self.btnMovie setHidden:YES];
        [self.btnBook setHidden:YES];
        [self.btnMusic setHidden:YES];
        [self.btnInternet setHidden:YES];
        [self.btnFileBrowse setHidden:YES];
        [self.btnPhoto setHidden:YES];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskLandscape;
}



#pragma mark -
-(void)updateBtnState
{
    [self updateBtnState:[self hasIpAddress]];
}

-(void)updateBtnState:(BOOL)state
{
    self.btnMovie.enabled=
    self.btnMusic.enabled=
    self.btnPhoto.enabled=
    self.btnBook.enabled=
    self.btnFileBrowse.enabled=
    self.btnInternet.enabled=
    
    self.btnMovie2.enabled=
    self.btnMusic2.enabled=
    self.btnPhoto2.enabled=
    self.btnBook2.enabled=
    self.btnFileBrowse2.enabled=
    self.btnInternet2.enabled=
    
    state;
    
    
}

-(bool)hasIpAddress
{
    return [RootData shared].path != nil;
}


-(void)figureOutRootPath
{
    [RootData shared].path = nil;
    
    UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    av.hidesWhenStopped=YES;
    av.center=self.view.center;
    av.autoresizingMask = ~0;
    [self.view addSubview:av];
    [av startAnimating];
    
    self.barReload.enabled = false;
    
    [self updateBtnState:FALSE];
    
    
    NSString *ipLocal = ipLocalHost();
    
    if (ipLocal)
    {
        char ip[20];
        
        strcpy( ip,  ipLocal.UTF8String );
        
        char *p = strrchr(ip, '.');
        
        strcpy( p + 1 , "254");
        
        NSString * ipRouter = [NSString stringWithUTF8String: ip];
        self.ipRouter = ipRouter;
        
        // get the root path.  192.168.x.x/Public
        NSString *rootPath = [NSString stringWithFormat:@"smb://%@/Public" , ipRouter ];
        
        [[RootData shared] setPathAndLoadAuthInfo:rootPath];
        
        [[RootData shared] reload:^(id result)
        {
            [av stopAnimating];
            [av removeFromSuperview];
            
            //self.barAuth.enabled = YES;
            self.barReload.enabled = YES;
            
            if([result isKindOfClass:[NSArray class]] && [result count] > 0 )
            {
                [self updateBtnState:YES];
            }
            else if ([result isKindOfClass:[NSError class]])
            {
                [RootData shared].path=nil;
                
                NSError *error = result;
                NSString *title = error.localizedDescription;
                NSString *msg = error.localizedFailureReason;
                [[[UIAlertView alloc]initWithTitle:title message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil), nil]show];
            }
        }];
        
       
    }
    else
    {
        [av stopAnimating];
        [av removeFromSuperview];
        
        //self.barAuth.enabled = YES;
        self.barReload.enabled = YES;
        
        [[[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Network not avaliable",nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    
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
//    NSArray *datas=@[@"group",@"userName",@"password"];
//    NSArray *placeH=@[@"workgroup",@"name",@"password"];
//   
//    
//    // iPad 版本
//    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad )
//    {
//        NSString *title = NSLocalizedString(@"Auth info", nil);
//        NSString *detail = [NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", nil) , self.ipRouter];
//        
//        sheetTableViewController *sheet=[[sheetTableViewController alloc]initWithTitle:title detailTitle:detail cancelBtn:NSLocalizedString(@"Cancel", nil) okBtn:NSLocalizedString(@"OK", nil) datas:datas images:nil placeHolders:placeH dismissed:^(NSArray *arrTableData) {
//            NSLog(@"%@",arrTableData);
//            if(arrTableData)
//            {
//                [RootData shared].group = arrTableData[0];
//                [RootData shared].userName = arrTableData[1];
//                [RootData shared].passWord = arrTableData[2];
//                
//                [self figureOutRootPath];
//            }
//
//        }];
//        [sheet show];
//    }
//    // iPhone,iPod 版本
//    else
//    {
//        UIAlertView *alert = [UIAlertView alloc];
//        
//    }
    

    
    //[self figureOutRootPath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)openMaps {
    //打开地图
    NSString*addressText = @"beijing";
    //@"1Infinite Loop, Cupertino, CA 95014";
    addressText =[addressText stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    
    NSString  *urlText = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@",addressText];
    NSLog(@"urlText=============== %@", urlText);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlText]];
}

- (IBAction)openEmail {
    //打开mail // Fire off an email to apple support
    [[UIApplication sharedApplication]openURL:[NSURL   URLWithString:@"mailto://devprograms@apple.com"]];
}

- (IBAction)openPhone {
    
    //拨打电话
    // Call Google 411
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://10086"]];
}

- (IBAction)openSms {
    //打开短信
    // Text toGoogle SMS
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"sms://10086"]];
}

-(IBAction)openBrowser {
    //打开浏览器
    // Lanuch any iPhone developers fav site
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://map.baidu.com/mobile/webapp/index/index/foo=bar/vt=map"]]; //@"http://blog.csdn.net/duxinfeng2010"
    
    LocalViewController *localViewController = [[LocalViewController alloc]init];
    [self.navigationController pushViewController:localViewController animated:YES];
    
}

- (IBAction)btnClicked:(UIButton*)sender {
    
    [RootData shared].currMediaType = sender.tag;
    
    UIViewController *nextViewController;
    
    enum MediaType type = sender.tag;
    
    switch (type) {
        case MediaTypeMovie:
        {
            TreeViewController *t = [[TreeViewController alloc] initAsHeadViewController];
            t.mediaType = type;
            t.path = [RootData shared].path;
            nextViewController = t;
            break;
        }
        case MediaTypeMusic:
        {
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            nextViewController = [sb instantiateViewControllerWithIdentifier:@"sbid_musicViewController"];
            break;
        }
        case MediaTypePhoto:
        {
            
//            CWPhotoViewerMasterViewController *masterViewController = [[CWPhotoViewerMasterViewController alloc] initWithNibName:@"CWPhotoViewerMasterViewController_iPhone" bundle:nil];
//            
//            nextViewController = masterViewController;
            
            nextViewController = [[smbCollectionViewController alloc]init];
            
            break;
        }
        case MediaTypeBook:
        {
            // @todo
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            nextViewController = [sb instantiateViewControllerWithIdentifier:@"sbidBook"];
            break;
        }
        case MediaTypeInternet:
        {
            [self openBrowser];
            break;
        }
        
        case MediaTypeFileBrowse:
        {
            //[self openPhone];
            break;
        }
        default:
            break;
    }
    
    
    [self.navigationController pushViewController:nextViewController animated:YES];
    
}
@end

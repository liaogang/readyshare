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

//#if define

//#define iOSDeviceScreenWidth                320
//#define iOSDeviceScreenHeight               (CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size)?568:480)
//#define iOSStatusBarHeight                  20
//#define Navi_Bar_Height_Portrait            44
//#define Navi_Bar_Height_Landscape           32

//#define iOSDeviceScreenWidth                768
//#define iOSDeviceScreenHeight               1024
//#define iOSStatusBarHeight                  20
//#define Navi_Bar_Height_Portrait            44
//#define Navi_Bar_Height_Landscape           44
//
//#endif

#define ICON_WIDTH 120
#define ICON_HEIGHT 120

#define IPAD_DEVICE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@interface MainViewController ()
<KxSMBProviderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnMovie;
@property (weak, nonatomic) IBOutlet UIButton *btnMusic;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnBook;
@property (weak, nonatomic) IBOutlet UIButton *btnInternet;
@property (weak, nonatomic) IBOutlet UIButton *btnFileBrowse;

@property (nonatomic,strong) NSString *ipRouter;
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
    
    self.navigationItem.rightBarButtonItems = @[ [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(figureOutRootPath)] ,
                                                 [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"auth"] style:UIBarButtonItemStylePlain target:self action:@selector(popupAuth) ] ];

    
    [self figureOutRootPath];
    
    
    if(IPAD_DEVICE)
    {
        iOSDeviceScreenWidth = 768;
        iOSDeviceScreenHeight = 1024;
        iOSStatusBarHeight = 20;
        Navi_Bar_Height_Portrait = 44;
        Navi_Bar_Height_Landscape = 44;
    }
    else
    {
        iOSDeviceScreenWidth = 320;
        iOSDeviceScreenHeight = (CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size)?568:480);
        iOSStatusBarHeight = 20;
        Navi_Bar_Height_Portrait = 44;
        Navi_Bar_Height_Landscape = 32;
    }
    

    UIImage *image = [UIImage imageNamed:@"main_bg.png"];
    self.view.layer.contents = (id) image.CGImage;
}

-(void)viewDidAppear:(BOOL)animated
{
    

}

- (void) viewDidLayoutSubviews
{
//    if(IPAD_DEVICE)
//    {
//        
//    }
//    else
//    {
    
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        {
            CGFloat screenWidth = iOSDeviceScreenWidth;
            CGFloat screenHeight = iOSDeviceScreenHeight-iOSStatusBarHeight;
            CGFloat detalOffsetY = (screenHeight - ICON_WIDTH*3)/2;
            [self.btnMovie setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnMusic setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 + ICON_WIDTH, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnPhoto setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnBook setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 + ICON_WIDTH, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnInternet setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 , detalOffsetY + 2*ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnFileBrowse setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 + ICON_WIDTH, detalOffsetY + 2*ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            
        }
        else if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
            CGFloat screenWidth = iOSDeviceScreenWidth;
            CGFloat screenHeight = iOSDeviceScreenHeight - Navi_Bar_Height_Landscape;
            CGFloat detalOffsetY = (screenWidth + iOSStatusBarHeight - ICON_HEIGHT *2)/2;
            
            [self.btnMovie setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnMusic setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2 + ICON_WIDTH, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnPhoto setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2 + 2*ICON_WIDTH, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnBook setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnInternet setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2  + ICON_WIDTH , detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnFileBrowse setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2 +  2*ICON_WIDTH, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
        }
   // }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self showViewWithOritation:toInterfaceOrientation];
    
}

- (void) showViewWithOritation:(UIInterfaceOrientation) orientation
{

//    if(IPAD_DEVICE)
//    {
//        
//    }
//    else
//    {
    
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        {
            CGFloat screenWidth = iOSDeviceScreenWidth;
            CGFloat screenHeight = iOSDeviceScreenHeight-iOSStatusBarHeight;
            CGFloat detalOffsetY = (screenHeight - ICON_WIDTH*3)/2;
            [self.btnMovie setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnMusic setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 + ICON_WIDTH, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnPhoto setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnBook setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 + ICON_WIDTH, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnInternet setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 , detalOffsetY + 2*ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnFileBrowse setFrame:CGRectMake((screenWidth - ICON_WIDTH *2)/2 + ICON_WIDTH, detalOffsetY + 2*ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            
        }
        else if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
            CGFloat screenWidth = iOSDeviceScreenWidth;
            CGFloat screenHeight = iOSDeviceScreenHeight - Navi_Bar_Height_Landscape;
            CGFloat detalOffsetY = (screenWidth + iOSStatusBarHeight - ICON_HEIGHT *2)/2;
            
            [self.btnMovie setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnMusic setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2 + ICON_WIDTH, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnPhoto setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2 + 2*ICON_WIDTH, detalOffsetY, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnBook setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnInternet setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2  + ICON_WIDTH , detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
            [self.btnFileBrowse setFrame:CGRectMake((screenHeight - ICON_WIDTH *3)/2 +  2*ICON_WIDTH, detalOffsetY + ICON_HEIGHT, ICON_WIDTH, ICON_HEIGHT)];
        }
 //   }
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
//        self.navigationItem.title = ipLocal;
        
        char ip[20];
        
        strcpy( ip,  ipLocal.UTF8String );
        
        char *p = strrchr(ip, '.');
        
        strcpy( p + 1 , "254");
        
        NSString * ipRouter = [NSString stringWithUTF8String: ip];
        self.ipRouter = ipRouter;
        
        // get the root path.  192.168.x.x/Public
        NSString *rootPath = [NSString stringWithFormat:@"smb://%@/Public" , ipRouter ];
        
        [RootData shared].path = rootPath;
        [[RootData shared] reload:^(id result)
        {
            if([result isKindOfClass:[NSArray class]] && [result count] > 0 )
            {
                [self updateBtnState];
            }
            else if ([result isKindOfClass:[NSError class]])
            {
                [RootData shared].path=nil;
                [self performSelector:@selector(popupAuth) withObject:nil afterDelay:0.5];
            }
        }];
        
       
    }
    else
    {
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
    NSArray *datas=@[@"group",@"userName",@"password"];
    NSArray *placeH=@[@"workgroup",@"name",@"password"];
   
    
    // iPad 版本
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad )
    {
        NSString *title = NSLocalizedString(@"Auth info", nil);
        NSString *detail = [NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", nil) , self.ipRouter];
        
        sheetTableViewController *sheet=[[sheetTableViewController alloc]initWithTitle:title detailTitle:detail cancelBtn:NSLocalizedString(@"Cancel", nil) okBtn:NSLocalizedString(@"OK", nil) datas:datas images:nil placeHolders:placeH dismissed:^(NSArray *arrTableData) {
            NSLog(@"%@",arrTableData);
            if(arrTableData)
            {
                [RootData shared].group = arrTableData[0];
                [RootData shared].userName = arrTableData[1];
                [RootData shared].passWord = arrTableData[2];
                
                [self figureOutRootPath];
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://map.baidu.com/mobile/webapp/index/index/foo=bar/vt=map"]]; //@"http://blog.csdn.net/duxinfeng2010"
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

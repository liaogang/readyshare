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



@interface MainViewController ()


@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithTitle:@"设置IP" style:UIBarButtonItemStyleDone target:self action:@selector(actionSetPath)];
    
    self.navigationItem.rightBarButtonItem = rightBtn;
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
    
    
    char ip[20] ;
    
    strcpy( ip,  ipLocal.UTF8String );
    
    char *p = strrchr(ip, '.');
    
    strcpy( p + 1 , "1");
    
    ipLocal = [NSString stringWithUTF8String: ip];
    
    [alert textFieldAtIndex:0].placeholder = ipLocal ;
    [alert textFieldAtIndex:0].text = ipLocal ;
    
    [alert show];
}

-(void)popupAuth
{
    NSArray *datas=@[@"group",@"userName",@"password"];
    NSArray *placeH=@[@"workgroup",@"name",@"password"];
   
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
    else
    {
        UIAlertView *alert = [UIAlertView alloc];
        
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  MusicViewController.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/19.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import "MusicViewController.h"
#import "RootData.h"
#import "musicTableViewCell.h"
#import "KxSMBProvider.h"
#import "PlayerEngine.h"


@interface MusicViewController ()
<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISlider *sliderVolumn;
@property (weak, nonatomic) IBOutlet UISlider *sliderProgress;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor=[UIColor clearColor];
    self.tableView.rowHeight = 42;
    self.tableView.layer.cornerRadius = 8;
    self.tableView.layer.masksToBounds = YES;
    
    RootData *r = [RootData shared];
    [r reload:^{
        if (r.error)
        {
            
        }
        else
        {
            [self.tableView reloadData];
        }
    }];
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

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    static NSString *cellIdentifier = @"musicTableCell";
    
    musicTableViewCell *cell ;//= [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(!cell)
        cell = [[musicTableViewCell alloc]initWithNib];
    
    NSArray *arr = [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered];

    KxSMBItemFile *file = arr[indexPath.row];
    
    cell.textNumber.text = @(indexPath.row + 1).stringValue;
    
    cell.textName.text = file.path.lastPathComponent;
    
//    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
//    
//    backView.backgroundColor = [UIColor clearColor];
//    
//    cell.backgroundView = backView;
    
    return cell;
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
      [cell setBackgroundColor:[UIColor clearColor]];
}


#pragma mark - Custom view for table header
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 48;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view= [[NSBundle mainBundle]loadNibNamed:@"musicTableHeader" owner:self options:nil][0];
    return view;
}

#pragma mark - delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arr = [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered];
    
    KxSMBItemFile *file = arr[indexPath.row];
    
    [file readDataToEndOfFile:^(id result)
    {
        if ([result isKindOfClass:[NSData class]]) {
            NSData *data = result;
            
            
            NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                    NSUserDomainMask,
                                                                    YES) lastObject];
            folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
            
            NSString *filename = file.path.lastPathComponent;
            
            
            NSString *path2 = [folder stringByAppendingPathComponent:filename];
            
            NSFileManager *fm =[[NSFileManager alloc]init];
            
            [fm createDirectoryAtURL:[NSURL fileURLWithPath:folder]
         withIntermediateDirectories:YES attributes:nil error:nil ];
            
            
            [data writeToFile:path2 atomically:YES];
            
            PlayerEngine *engine = [[PlayerEngine alloc]init];
            [engine playURL: [NSURL fileURLWithPath:path2]];
            
            
            
        }
        
    }];
    
}

@end

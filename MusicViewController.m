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

@interface MusicViewController ()
<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISlider *sliderVolumn;
@property (weak, nonatomic) IBOutlet UISlider *sliderProgress;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
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
    static NSString *cellIdentifier = @"musicTableCell";
    
    musicTableViewCell *cell ;//= [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(!cell)
        cell = [[musicTableViewCell alloc]initWithNib];
    
    NSArray *arr = [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered];

    KxSMBItemFile *file = arr[indexPath.row];
    
    cell.textNumber.text = @(indexPath.row).stringValue;
    
    cell.textName.text = file.path.lastPathComponent;
    
    return cell;
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

@end

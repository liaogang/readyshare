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

#import "PlayerTypeDefines.h"
#import "PlayerEngine.h"
#import "PlayerMessage.h"


@interface MusicViewController ()
<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISlider *sliderVolumn;
@property (weak, nonatomic) IBOutlet UISlider *sliderProgress;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) int playingIndex;
@property (nonatomic) enum PlayOrder order;
@property (nonatomic,strong) PlayerEngine *engine;
@property (nonatomic) int idDownload;
@end

@implementation MusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor=[UIColor clearColor];
    self.tableView.rowHeight = 42;
    self.tableView.layer.cornerRadius = 8;
    self.tableView.layer.masksToBounds = YES;
    
    self.playingIndex = -1;
    self.order = playorder_default;
    
    self.engine = [[PlayerEngine alloc]init];
    addObserverForEvent(self, @selector(playNext), EventID_track_stopped_playnext);
    
    RootData *r = [RootData shared];
    [r reload:^{
        
        self.idDownload = r.idReloadDate;
        
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
    [self playItemAtIndex:indexPath.row];
}

-(void)playItemAtIndex:(int)index
{
    NSArray *arr = [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered];
    
    KxSMBItemFile *file = arr[index];
    
    BOOL exsit = false;
    
    NSString *fullFileName = [[RootData shared] tempFileExsit:file.path.lastPathComponent :&exsit];
    
    if (exsit)
    {
        self.playingIndex = index;
        [_engine playURL: [NSURL fileURLWithPath:fullFileName]];
    }
    else
    {
        [file readDataToEndOfFile:^(id result)
         {
             if ([result isKindOfClass:[NSData class]])
             {
                 NSData *data = result;
                 [data writeToFile:fullFileName atomically:YES];
 
                 
                 self.playingIndex = index;
                 [_engine playURL: [NSURL fileURLWithPath:fullFileName]];
             }
         }];
    }
    
}


-(void)playNext
{
    int next = getNext(self.order, self.playingIndex, 0, [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered].count );
    
    [self playItemAtIndex: next ];
}

@end

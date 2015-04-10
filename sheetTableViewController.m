//
//  sheettTableViewController.m
//  ReadyShare
//
//  Created by liaogang on 5/26/14.
//  Copyright (c) 2014 gang.liao. All rights reserved.
//

#import "sheetTableViewController.h"


const int TAG_TEXT_FIELD = 1234 ;








//@interface UITableViewCell (f)
//
//@end
//
//@implementation UITableViewCell (f)
//
//- (void)setFrame:(CGRect)frame {
//    const int inset = 20;
//    frame.origin.x += inset;
//    frame.size.width -= 2 * inset;
//    [super setFrame:frame];
//}
//
//@end

@interface sheetTableViewController ()
<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
{
    UITableView *_tableView;
    
    
    NSArray *_datas,*_images,*_placeHolders;
    NSString *_strTitle,*_strDetail;
    NSString *_strCancel,*_strOK;
    
    
    CGFloat _maxLabelLength;
    
    NSMutableArray *_texts;
    UITextField *_currInput;
}
@property (copy ,nonatomic) sheetTableViewCallBack callback;
@end

@implementation sheetTableViewController


-(id)initWithTitle:(NSString *)title detailTitle:(NSString*)detailTitle cancelBtn:(NSString*)cancel okBtn:(NSString*)ok datas:(NSArray*)datas images:(NSArray*)images placeHolders:(NSArray*)placeHolders dismissed:(sheetTableViewCallBack)callback
{
    self =[super init];
    if (self) {
        self.modalPresentationStyle=UIModalPresentationFormSheet;

        _strTitle=title;
        _strDetail=detailTitle;
        _strCancel=cancel;
        _strOK=ok;
        _datas=datas;
        _images=images;
        _placeHolders=placeHolders;
        _callback=callback;
        _texts = [NSMutableArray arrayWithArray: _datas];
    }
    
    return self;
}

-(void)dealloc
{
    _tableView =nil;
    
    _datas=nil,_images=nil,_placeHolders=nil;
    _strTitle=nil,_strDetail=nil;
    _strCancel=nil,_strOK=nil;
    
    _texts=nil;
    _currInput=nil;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor=[UIColor whiteColor];
    CGSize sz=self.view.frame.size;

    _tableView=[[UITableView alloc]initWithFrame:CGRectMake(0, 0,sz.width , sz.height) style:UITableViewStyleGrouped];
    _tableView.delegate=self;
    _tableView.dataSource=self;
    _tableView.autoresizingMask = 0xffffffff;
    
    [self.view addSubview: _tableView];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row=indexPath.row;
    
    UITableViewCell *cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"asdf"];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text=_datas[row];
    
    if(_images.count >= row +1)
    {
        NSString *strImage = [_images objectAtIndex:row];
        [cell.imageView setImage:[UIImage imageNamed:strImage]];
    }
    
    if(_maxLabelLength == 0)
    {
        for (NSString *text in _datas) {
            CGSize szString = [text sizeWithAttributes: @{NSFontAttributeName:cell.textLabel.font}];
            
            if(szString.width > _maxLabelLength)
                _maxLabelLength = szString.width;
        }
    }


    UITextField *t=[[UITextField alloc]initWithFrame:CGRectMake( _maxLabelLength + 40, 4, 120, 30)];
    //垂直居中
    t.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [t setCenter:CGPointMake(t.center.x, cell.contentView.center.y)];
    t.autoresizingMask=UIViewAutoresizingFlexibleWidth;

    if(_placeHolders.count >= row +1)
    {
        NSString *pla=[_placeHolders objectAtIndex:row];
        t.placeholder=pla;
    }
    
    //set the tag to row index.
    t.tag = TAG_TEXT_FIELD + row;
    
    t.delegate=self;
    [cell.contentView addSubview:t];
    
    
    return cell;
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UITextField *t= (UITextField*)[cell.contentView viewWithTag:TAG_TEXT_FIELD + indexPath.row];
        [t becomeFirstResponder];
        //_currInput=t;
    }
}


-(void)show
{
    //right
    UIBarButtonItem *right = [[UIBarButtonItem alloc]initWithImage:nil landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(actionOK:)];
    
    //[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleDone target:self action:@selector(actionOK:)];
    self.navigationItem.rightBarButtonItem =right;
    right.title=_strOK;
    
    
    //left
    UIBarButtonItem *left= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancelled:)];
    self.navigationItem.leftBarButtonItem =left;
    
    
    self.navigationItem.title=_strTitle;
    if(_strDetail && ![_strDetail isEqualToString:@""])
        self.navigationItem.prompt=_strDetail;
    
    UINavigationController *navigationController =[[UINavigationController alloc]initWithRootViewController:self];
    
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.navigationController animated:YES completion:nil];
}

-(void)hide
{
    
    [self dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication]setStatusBarHidden:YES];
    }];
}



- (void)actionCancelled:(id)sender {
    
    [self hide];
    if(_callback)
        _callback(nil);
}

- (void)actionOK:(id)sender {

     _texts[_currInput.tag - TAG_TEXT_FIELD] = _currInput.text;
    
    [self hide];
    if(_callback)
        _callback(_texts);
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _currInput = textField;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    _texts[textField.tag - TAG_TEXT_FIELD] = textField.text;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    int index = textField.tag - TAG_TEXT_FIELD;
    
    BOOL bLast = index +1 == _datas.count;
    
    if(!bLast)
    {
        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:1] ];
        
        //move focus to next
        UITextField *t= (UITextField*) [cell.contentView viewWithTag:index + 1 + TAG_TEXT_FIELD ] ;
        [t becomeFirstResponder];
        _currInput=t;
    }
    else
    {
        [self actionOK:nil];
    }
    
    
    
    
    return NO;
}
@end

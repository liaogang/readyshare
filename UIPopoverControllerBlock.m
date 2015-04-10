//
//  UIPopoverControllerBlock.m
//  ReadyShare
//
//  Created by liaogang on 5/22/14.
//  Copyright (c) 2014 gang.liao. All rights reserved.
//

#import "UIPopoverControllerBlock.h"
@interface pickerTableViewController : UITableViewController
@end

@interface UIPopoverControllerBlock () <UIPopoverControllerDelegate>
{
    pickerTableViewController *_tableViewController;
}
@end


@interface pickerTableViewController ()
{
    UIPopoverControllerBlock *_popover;
    NSArray *_arrObject,*_arrImages;
    popOverControllerCallBack _callback;
}
- (id)initWithData:(NSArray*)arr images:(NSArray*)arrImages Style:(UITableViewStyle)style;
//-(void)setData:(NSArray*)arr;
-(void)setCallBack:(popOverControllerCallBack)callback;
-(void)setParent:(UIPopoverControllerBlock*)popover;
@end


@implementation UIPopoverControllerBlock
-(id)initWithObjects:(NSArray*)arr images:(NSArray*)arrImages CallBack:(popOverControllerCallBack)callback
{
    _tableViewController = [[pickerTableViewController alloc]initWithData:(NSArray*)arr images:arrImages Style:UITableViewStylePlain];
    if(_tableViewController){
    self = [super initWithContentViewController:_tableViewController];
    if (self) {
        [_tableViewController setCallBack: callback ];
        [_tableViewController setParent:self];
        self.delegate=self;
    }
    }
    
    return self;
}

@end





@implementation pickerTableViewController
-(void)setParent:(UIPopoverControllerBlock*)popover
{
    _popover=popover;
}

//-(void)setData:(NSArray*)arr
//{
//    _arrObject = arr;
//}

-(void)setCallBack:(popOverControllerCallBack)callback
{
    _callback = [callback copy];
}


-(void)reset
{
    //disable the scroll
    self.tableView.scrollEnabled=FALSE;
    
    //Make row selections persist.
    //self.clearsSelectionOnViewWillAppear = NO;
    
    //Calculate how tall the view should be by multiplying the individual row height
    //by the total number of rows.
    NSInteger rowsCount = [_arrObject count];
    NSInteger singleRowHeight = [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    NSInteger totalRowsHeight = rowsCount * singleRowHeight;
    
    //Calculate how wide the view should be by finding how wide each string is expected to be
    CGFloat largestLabelWidth = 0;
    for (NSString *colorName in _arrObject) {
        //Checks size of text using the default font for UITableViewCell's textLabel.
        CGSize labelSize = [colorName sizeWithFont:[UIFont boldSystemFontOfSize:20.0f]];
        if (labelSize.width > largestLabelWidth) {
            largestLabelWidth = labelSize.width;
        }
    }
    
    //Add a little padding to the width
    CGFloat popoverWidth = largestLabelWidth + 100;
    
    //Set the property to tell the popover container how big this view will be.
    self.preferredContentSize=CGSizeMake(popoverWidth, totalRowsHeight);
    //self.contentSizeForViewInPopover = CGSizeMake(popoverWidth, totalRowsHeight);
}


-(id)init
{
    self=[super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (id)initWithData:(NSArray*)arr images:(NSArray*)arrImages Style:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _arrImages = arrImages;
        _arrObject =arr;
         [self reset];
        
    }
    return self;
}


-(void)dealloc
{
    _popover=nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_arrObject count];
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
     UITableViewCell *     cell=[[UITableViewCell alloc]init];
     // Configure the cell...
     [cell.imageView setImage:[UIImage imageNamed:_arrImages[indexPath.row]]];
     cell.textLabel.text=_arrObject[indexPath.row];
     return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_callback)
        _callback(_popover,indexPath.row);
}
@end
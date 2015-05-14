//
//  LocalLibraryViewController.m
//  GenieiPad
//
//  Created by geine on 14-3-27.
//
//

#define TAG_LOAD 1042

#import "LocalLibraryViewController.h"

@implementation LocalLibraryViewController {
    NSMutableArray *fileArr;
    NSMutableString *fileDate;
}

@synthesize loadAlertView;

- (id)initWithTag:(BOOL)is_pic {
    if (self = [super init]) {
        fileArr = [[NSMutableArray alloc] initWithCapacity:42];
        fileDate = [[NSMutableString alloc] initWithCapacity:42];
        self.is_filterPic = is_pic;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    lib_tableView = [[UITableView alloc]
                     initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    lib_tableView.delegate = self;
    lib_tableView.dataSource = self;
    
    self.view = lib_tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getAllLibFiles];
    
    NSArray *tmpDirectory = [[NSFileManager defaultManager]
                             contentsOfDirectoryAtPath:NSTemporaryDirectory()
                             error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager]
         removeItemAtPath:
         [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file]
         error:NULL];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    [loadAlertView dismissWithClickedButtonIndex:0 animated:YES];
    return [photoLB_fileArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"cellID"];
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSInteger row = [indexPath row];
    NSURL *url = [photoLB_fileArray objectAtIndex:row];
    
    NSData *imagedata = [[NSData alloc] initWithContentsOfURL:url];
    UIImage *originImage = [[UIImage alloc] initWithData:imagedata];
    UIImage *formatImage =
    [originImage imageByScalingAndCroppingForSize:CGSizeMake(32, 32)];
    cell.imageView.image = formatImage;
    
    cell.textLabel.text = [photoLB_nameArray objectAtIndex:row];
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    cell.imageView.image = [photoLB_thumArray objectAtIndex:row];
    
    unsigned long long size =
    [[photoLB_sizeArray objectAtIndex:row] unsignedLongLongValue];
    NSString *unit;
    CGFloat value;
    
    if (size < 1024) {
        
        value = size;
        unit = @"B";
        
    } else if (size < 1048576) {
        
        value = size / 1024.f;
        unit = @"KB";
        
    } else {
        
        value = size / 1048576.f;
        unit = @"MB";
    }
    cell.detailTextLabel.text =
    [NSString stringWithFormat:@"%.1f%@", value, unit];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = [indexPath row];
    
    NSString *path = [[photoLB_fileArray objectAtIndex:row] absoluteString];
    
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = NSLocalizedStringFromTable(@"back", nil, nil);
    self.navigationItem.backBarButtonItem = backBtn;
    
    LocaFileSelectedViewController *selectView =
    [[LocaFileSelectedViewController alloc] init];
    NSLog(@"%p", selectView);
    [selectView.filePath setString:path];
    selectView.fileName = [photoLB_nameArray objectAtIndex:row]; // path;
    selectView.library = self.library;
    selectView.fileSize = [photoLB_sizeArray objectAtIndex:row];
    selectView.is_libFile = YES;
    selectView.photosArray = photoLB_fileArray;
    selectView.fileNameArray = photoLB_nameArray;
    selectView.fileSizeArray = photoLB_sizeArray;
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    [self.navigationController.view.layer addAnimation:transition
                                                forKey:kCATransition];
    
    [self.navigationController pushViewController:selectView animated:NO];
}

#pragma mark - get photo and movie from phot library
- (void)getAllLibFiles {
    NSString *loadMsg;
    if (self.is_filterPic) {
        loadMsg = NSLocalizedString(@"photos loading", nil);
    } else {
        loadMsg = NSLocalizedString(@"videos loading", nil);
    }
    
    loadAlertView = [[UIAlertView alloc] initWithTitle:nil
                                               message:loadMsg
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:nil, nil];
    [loadAlertView show];
    
    photoLB_fileArray = [[NSMutableArray alloc] init];
    photoLB_sizeArray = [[NSMutableArray alloc] init];
    photoLB_nameArray = [[NSMutableArray alloc] init];
    photoLB_thumArray = [[NSMutableArray alloc] init];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{ [self filterPhotoAndVideo]; });
}

- (void)filterPhotoAndVideo {
    static NSUInteger num = 1;
    
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) =
    ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        //        NSAssert([NSThread isMainThread],@"assetGroupEnumerator");
        if (result != nil) {
            // if([[result valueForProperty:ALAssetPropertyType]
            // isEqualToString:ALAssetTypePhoto])
            {
                //[assetURLDictionaries addObject:[result
                //valueForProperty:ALAssetPropertyURLs]];
                
                NSString *date = [[NSString
                                   stringWithFormat:@"%@",
                                   [result valueForProperty:ALAssetPropertyDate]]
                                  stringByReplacingOccurrencesOfString:@" "
                                  withString:@"_"];
                NSMutableString *fileName =
                [[NSMutableString alloc] initWithCapacity:42];
                [fileName setString:[date stringByReplacingOccurrencesOfString:@":"
                                                                    withString:@"-"]];
                [fileName deleteCharactersInRange:[fileName rangeOfString:@"_+0000"]];
                if ([fileName isEqualToString:fileDate]) {
                    [fileName insertString:[NSString stringWithFormat:@"(%d)", num]
                                   atIndex:[fileName length]];
                    num++;
                } else {
                    [fileDate setString:fileName];
                    num = 1;
                }
                
                NSURL *url = (NSURL *)[[result defaultRepresentation] url];
                [photoLB_fileArray addObject:url];
                
                NSString *na = [NSString stringWithString:[url absoluteString]];
                NSString *localName;
                if ([[NSPredicate predicateWithFormat:@"SELF ENDSWITH[cd] 'mov'"]
                     evaluateWithObject:na]) {
                    localName = [NSString stringWithFormat:@"MOV_%@.mov", fileName];
                } else if ([[NSPredicate
                             predicateWithFormat:@"SELF ENDSWITH[cd] 'mp4'"]
                            evaluateWithObject:na]) {
                    localName = [NSString stringWithFormat:@"MP4_%@.mp4", fileName];
                } else {
                    localName = [NSString stringWithFormat:@"IMG_%@.png", fileName];
                }
                [photoLB_thumArray
                 addObject:[UIImage imageWithCGImage:[result thumbnail]]];
                [photoLB_nameArray addObject:localName];
                
                unsigned long long size = [[result defaultRepresentation] size];
                [photoLB_sizeArray
                 addObject:[NSNumber numberWithUnsignedLongLong:size]];
            }
        }
    };
    
    NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) =
    ^(ALAssetsGroup *group, BOOL *stop) {
        //        NSAssert([NSThread isMainThread],@"assetGroupEnumerator");
        NSLog(@"one group done");
        
        if (group != nil) {
            if (self.is_filterPic) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            } else {
                [group setAssetsFilter:[ALAssetsFilter allVideos]];
            }
            [group enumerateAssetsUsingBlock:assetEnumerator];
            [assetGroups addObject:group];
            NSLog(@"Number of assets in group :%ld", (long)[group numberOfAssets]);
            NSLog(@"asset group is:%@", assetGroups);
            
            [lib_tableView reloadData];
        }
    };
    
    assetGroups = [[NSMutableArray alloc] init];
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                usingBlock:assetGroupEnumerator
                              failureBlock:^(NSError *error) {
                                  NSLog(@"A problem occurred");
                              }];
}

@end

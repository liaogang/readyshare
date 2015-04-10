
#import "SDWebImageManager.h"

@class KxSMBItemFile;

@interface UIImageView (WebCache_Smb)

- (void)setImageWithSmbFile:(KxSMBItemFile *)smbFile needRefresh:(BOOL)needRefresh;

- (void)setImageWithSmbFile:(KxSMBItemFile *)smbFile  placeholderImage:(UIImage *)placeholder needRefresh:(BOOL)needRefresh;

- (void)setImageWithSmbFile:(KxSMBItemFile *)smbFile placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock needRefresh:(BOOL)needRefresh;

- (void)setImageWithSmbItem:(KxSMBItemFile *)smbItem placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock needRefresh:(BOOL)needRefresh;


@end



@interface SDWebImageManager (sdweb_smb)

- (id <SDWebImageOperation>)downloadWithSmbItem:(KxSMBItemFile *)smbItem options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedWithFinishedBlock)completedBlock;

@end
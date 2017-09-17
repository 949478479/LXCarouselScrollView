//
//  LXCarouselScrollView+SDWebImage.m
//
//  Created by 从今以后 on 2017/9/17.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import "LXCarouselScrollView+SDWebImage.h"
#import "SDWebImageManager.h"
#import <objc/runtime.h>

@implementation LXCarouselScrollView (SDWebImage)

- (void)lx_setPlaceholderImage:(UIImage *)lx_placeholderImage {
	objc_setAssociatedObject(self, @selector(lx_placeholderImage), lx_placeholderImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)lx_placeholderImage {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)lx_setShowActivityIndicator:(BOOL)lx_showActivityIndicator {
	objc_setAssociatedObject(self, @selector(lx_showActivityIndicator), @(lx_showActivityIndicator), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)lx_showActivityIndicator {
	return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (NSMutableSet *)lx_pendingURLs {
	NSMutableSet *pendingURLs = objc_getAssociatedObject(self, _cmd);
	if (!pendingURLs) {
		pendingURLs = [NSMutableSet new];
		objc_setAssociatedObject(self, _cmd, pendingURLs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return pendingURLs;
}

- (NSArray<NSURL *> *)lx_imageURLs {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)lx_setImageURLs:(NSArray<NSURL *> *)imageURLs
{
	[self invalidate];
	[self.lx_pendingURLs removeAllObjects];

	objc_setAssociatedObject(self, @selector(lx_imageURLs), imageURLs, OBJC_ASSOCIATION_COPY_NONATOMIC);
	self.numberOfPages = self.lx_imageURLs.count;

	__weak typeof(self) weakSelf = self;
	[self configureImageViewUsingBlock:^(LXCarouselImageView * _Nonnull imageView, NSInteger index) {
		__strong typeof(weakSelf) self = weakSelf; if (!self) return;

		imageView.tag = index;
		imageView.image = self.lx_placeholderImage ?: nil;

		if (!self.lx_placeholderImage && self.lx_showActivityIndicator) {
			[imageView showActivityIndicator];
		}

		NSURL *url = self.lx_imageURLs[index];
		if ([self.lx_pendingURLs containsObject:url]) {
			return;
		}
		[self.lx_pendingURLs addObject:url];

		NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
		[[SDImageCache sharedImageCache] queryCacheOperationForKey:key done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {

			if (image) {
				[self.lx_pendingURLs removeObject:url];
				[self lx_setImageIfPossible:image forImageView:imageView index:index];
			}
			else {
				[[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
					__strong typeof(weakSelf) self = weakSelf; if (!self) return;

					if (image) {
						[self lx_setImageIfPossible:image forImageView:imageView index:index];
						[[SDImageCache sharedImageCache] storeImage:image forKey:key completion:^{
							[self.lx_pendingURLs removeObject:url];
						}];
					} else {
						[self.lx_pendingURLs removeObject:url];
					}
				}];
			}
		}];
	}];

	[self reloadData];
	[self startTimer];
}

- (void)lx_setImageIfPossible:(UIImage *)image forImageView:(LXCarouselImageView *)imageView index:(NSInteger)index {
	if (index == imageView.tag) {
		imageView.image = image;
		[imageView hideActivityIndicator];
	}
}

@end

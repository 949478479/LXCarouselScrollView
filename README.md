# LXScrollView

基于 UIScrollView 的轮播图

```objective-c
__weak typeof(self) weakSelf = self;

self.scrollView.numberOfPages = 5;
[self.scrollView configureImageViewAtIndex:^(UIImageView * _Nonnull imageView, NSUInteger index) {
    imageView.image = weakSelf.images[index];
}];

[self.scrollView configurePageControlForCurrentPage:^(NSUInteger currentPage) {
    weakSelf.pageControl.currentPage = currentPage;
}];

[self.scrollView notifyWhenImageViewDidTapUsingBlock:^(UIImageView * _Nonnull imageView, NSUInteger index) {
    NSLog(@"%@, index:%@", imageView, @(index));
}];
    
self.scrollView.timeInterval = 2;
[self.scrollView startTimer];
  ```
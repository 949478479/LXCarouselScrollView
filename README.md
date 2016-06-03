# LXScrollView

基于 UIScrollView 的轮播图，可通过 block 对 imageView 和 pageControl 进行设置，并提供了定时器和点击图片处理。

```objective-c
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.images = @[
        [UIImage imageNamed:@"image_0"],
        [UIImage imageNamed:@"image_1"],
        [UIImage imageNamed:@"image_2"],
        [UIImage imageNamed:@"image_3"],
        [UIImage imageNamed:@"image_4"], ];

    self.pageControl.numberOfPages = 5;

    self.scrollView.timeInterval = 2;
    self.scrollView.numberOfPages = 5;

    __weak typeof(self) weakSelf = self;

    [self.scrollView configureImageViewAtIndex:^(UIImageView * _Nonnull imageView, NSUInteger index) {
        imageView.image = weakSelf.images[index];
    }];

    [self.scrollView configurePageControlForCurrentPage:^(NSUInteger currentPage) {
        weakSelf.pageControl.currentPage = currentPage;
    }];

    [self.scrollView notifyWhenImageViewDidTapUsingBlock:^(UIImageView * _Nonnull imageView, NSUInteger index) {
        NSLog(@"%@, index:%@", imageView, @(index));
    }];

    [self.scrollView reloadData];

    [self.scrollView startTimer];
}
```

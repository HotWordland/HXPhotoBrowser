//
//  HXPhotoImageView.m
//  HXPhotoBrowser
//
//  Created by suin on 2018/8/16.
//  Copyright © 2018年 韩旭. All rights reserved.
//

#import "HXPhotoImageView.h"
#import "HXPhotoBrowserMacro.h"
#import "HXPhotoHelper.h"

@interface HXPhotoImageView()<UIScrollViewDelegate>
@property (nonatomic, strong) UIVisualEffectView *effectView;
@property (nonatomic, strong) UIView *processView;
@property (nonatomic, strong) UIImage *blurImage;
@end

@implementation HXPhotoImageView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setScrollView];
//        [self setEffectView];
        [self setProcessView];
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)setMaskHidden:(BOOL)hidden{
    if (self.effectView) {
        self.effectView.hidden = hidden;
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return _imageView;
}

- (CGPoint)centerOfScrollViewContent:(UIScrollView *)scrollView
{
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    CGPoint center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
    return center;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    _scrollView.maximumZoomScale = kHXPhotoBrowserZoomMax;
    _imageView.center = [self centerOfScrollViewContent:scrollView];
}

- (void)setScrollView{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:_scrollView];
    _scrollView.delegate = self;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.bounces = NO;
    _scrollView.minimumZoomScale = kHXPhotoBrowserZoomMin;
    _scrollView.maximumZoomScale = kHXPhotoBrowserZoomMax;
    _scrollView.zoomScale = kHXPhotoBrowserZoomMin;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    CGFloat width = kHXSCREEN_WIDTH;
    CGFloat height = width;
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, (kHXSCREEN_HEIGHT - height) / 2, width, height)];
    [_scrollView addSubview:_imageView];
    [_imageView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    [_imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"frame"]) {
        CGRect rect = [[change objectForKey:@"new"] CGRectValue];
        _scrollView.contentSize = rect.size;
    }
    
    if ([keyPath isEqualToString:@"image"]) {
        if (!self.blurImage && [[change objectForKey:@"new"] isKindOfClass:[UIImage class]]) {
            self.blurImage = [change objectForKey:@"new"];
            if (!self.isfinish) {
                self.imageView.image = [[HXPhotoHelper shared] blurryImage:self.blurImage withBlurLevel: 1];
            }
        }
    }
}


- (void)setEffectView{
    UIBlurEffect *blurEffect =[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _effectView =[[UIVisualEffectView alloc]initWithEffect:blurEffect];
    _effectView.frame = CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height);
    _effectView.hidden = YES;
    [self.imageView addSubview:_effectView];
    _effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
}

- (void)setProcessView{
    _processView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, kHXPhotoBrowserProcessHeight)];
    [_imageView addSubview:_processView];
    _processView.backgroundColor = [UIColor whiteColor];
}

- (void)finishProcess{
    
    [UIView animateWithDuration:0.2 animations:^{
        self.effectView.alpha = 0;
        self.processView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.effectView removeFromSuperview];
        self.effectView = nil;
        [self.processView removeFromSuperview];
        self.processView = nil;
    }];
}

- (void)setReceivedSize:(CGFloat)receivedSize{
    _receivedSize = receivedSize;
    
    CGFloat scale = receivedSize / _expectedSize;
    CGRect frame = CGRectMake(0, 0, scale * kHXSCREEN_WIDTH, kHXPhotoBrowserProcessHeight);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.1 animations:^{
            self.processView.frame = frame;
            if (self.blurImage) {
                self.imageView.image = [[HXPhotoHelper shared] blurryImage:self.blurImage withBlurLevel: 1 - scale];
            }
        }];
    });
}

- (void)dealloc{
    [_imageView removeObserver:self forKeyPath:@"frame"];
}


@end

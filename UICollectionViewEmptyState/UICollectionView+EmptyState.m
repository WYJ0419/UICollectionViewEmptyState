//
//  UICollectionView+EmptyState.m
//  UICollectionViewEmptyState
//
//  Created by Jonathan Crooke on 14/05/2013.
//  Copyright (c) 2013 Jon Crooke. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "UICollectionView+EmptyState.h"
#import "ObjcAssociatedObjectHelpers.h"
#import "EXTSwizzle.h"

@interface UICollectionView (EmptyStatePrivate)
- (void) __empty_layoutSubviews;
- (void) __empty_layoutSubviews_original;
@end

@implementation UICollectionView (EmptyState)

SYNTHESIZE_ASC_PRIMITIVE(emptyState_showAnimationDuration,
                         setEmptyState_showAnimationDuration,
                         NSTimeInterval)
SYNTHESIZE_ASC_PRIMITIVE(emptyState_hideAnimationDuration,
                         setEmptyState_hideAnimationDuration,
                         NSTimeInterval)
SYNTHESIZE_ASC_PRIMITIVE(emptyState_shouldRespectSectionHeader,
                         setEmptyState_shouldRespectSectionHeader,
                         BOOL)
SYNTHESIZE_ASC_OBJ_BLOCK(emptyState_view,
                         setEmptyState_view,
                         ^{},
                         ^
{
  static BOOL __segue_swizzled = NO;
  if (!__segue_swizzled) {
    EXT_SWIZZLE_INSTANCE_METHODS(UICollectionView,
                                 layoutSubviews,
                                 __empty_layoutSubviews,
                                 __empty_layoutSubviews_original);
    __segue_swizzled = YES;
  }
});

- (void) __empty_layoutSubviews {
  [self __empty_layoutSubviews_original];

  // section header respect requires UICollectionViewDelegateFlowLayout right now...
  if (self.emptyState_view && self.emptyState_shouldRespectSectionHeader &&
      ![self.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]])
  {
    [NSException raise:@"UICollectionView+EmptyState Exception"
                format:
     @"Only compatible with %@ when emptyState_shouldRespectSectionHeader = YES." \
     " Cannot be used with %@",
     NSStringFromClass([UICollectionViewFlowLayout class]),
     NSStringFromClass([self.collectionViewLayout class])];
  }

  NSUInteger totalItems = 0;
  NSUInteger numberOfSections = 1;
  if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
    numberOfSections = [self.dataSource numberOfSectionsInCollectionView:self];
  }

  for (NSUInteger section = 0; section < numberOfSections; ++section) {
    totalItems += [self.dataSource collectionView:self numberOfItemsInSection:section];
  }

  if (totalItems) {
    // remove
    if (self.emptyState_view.superview) {
      [UIView animateWithDuration:self.emptyState_hideAnimationDuration animations:^{
        self.emptyState_view.alpha = 0.0;
      } completion:^(BOOL finished) {
        [self.emptyState_view removeFromSuperview];
      }];
    }
  } else if (!totalItems) {

    // show
    CGRect bounds = self.bounds;

    id <UICollectionViewDelegateFlowLayout> delegate = (id) self.delegate;
    UICollectionViewFlowLayout *layout = (id) self.collectionViewLayout;

    // don't overlay header?
    if (self.emptyState_shouldRespectSectionHeader) {

      // is there actually a header to be displayed?
      if (numberOfSections &&
          [self.dataSource collectionView:self
        viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader
                              atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]])
      {
        // reveal the first section's supplementary view
        CGSize size = layout.headerReferenceSize;

        if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
          size = [delegate collectionView:self
                                   layout:layout
          referenceSizeForHeaderInSection:0];
        }

        //
        CGRect slice;
        CGRectDivide(bounds, &slice, &bounds, size.height, CGRectMinYEdge);
        self.emptyState_view.frame = bounds;
      }
    }

    // always update bounds
    self.emptyState_view.frame = bounds;

    // add view
    if (self.emptyState_view.superview != self) {
      // not visible, add
      self.emptyState_view.alpha = 0.0;
      [self addSubview:self.emptyState_view];
      [UIView animateWithDuration:self.emptyState_showAnimationDuration animations:^{
        self.emptyState_view.alpha = 1.0;
      }];
    }
  }
}

@end

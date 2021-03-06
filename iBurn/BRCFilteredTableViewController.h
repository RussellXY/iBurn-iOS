//
//  BRCFilteredTableViewController.h
//  iBurn
//
//  Created by Christopher Ballinger on 7/28/14.
//  Copyright (c) 2014 Burning Man Earth. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRCFilteredTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UISegmentedControl *segmentedControl;

// Shared Database Views with Subclasses
@property (nonatomic, strong, readonly) NSString *distanceViewName;
@property (nonatomic, strong, readonly) NSString *favoritesFilterForDistanceViewName;

@property (nonatomic, strong, readonly) Class viewClass;

- (instancetype) initWithViewClass:(Class)viewClass;

@end

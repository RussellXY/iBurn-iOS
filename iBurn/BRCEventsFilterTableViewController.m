//
//  BRCEventsFilterTableViewController.m
//  iBurn
//
//  Created by David Chiles on 8/1/14.
//  Copyright (c) 2014 Burning Man Earth. All rights reserved.
//

#import "BRCEventsFilterTableViewController.h"
#import "BRCEventObject.h"
#import "NSUserDefaults+iBurn.h"
#import "BRCDatabaseManager.h"
#import "YapDatabaseFilteredView.h"
#import "YapDatabaseFilteredViewTransaction.h"

NSString *const BRCFilterTableViewCellIdentifier = @"BRCFilterTableViewCellIdentifier";

@interface BRCEventTypeContainer : NSObject

@property (nonatomic) BRCEventType type;
@property (nonatomic) BOOL isSelected;
@property (nonatomic, strong) NSString *title;

@end

@implementation BRCEventTypeContainer

- (instancetype)initWithType:(BRCEventType)type
{
    if (self = [self init]) {
        self.type = type;
        self.title = [BRCEventObject stringForEventType:self.type];
    }
    return self;
}

@end

@interface BRCEventsFilterTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *tableViewDataSource;
@property (nonatomic, weak) id <BRCEventsFilterTableViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *timeStrings;
@property (nonatomic, strong) NSArray *eventTypeArray;

@property (nonatomic) BOOL showExpiredEvents;
@property (nonatomic) BOOL shouldSortEventsByStartTime;

@property (nonatomic, strong) YapDatabaseConnection* databaseConnection;

@end

@implementation BRCEventsFilterTableViewController

- (id)init
{
    if (self = [super init]) {
        self.databaseConnection = [BRCDatabaseManager sharedInstance].readWriteDatabaseConnection;
    }
    return self;
}

- (instancetype)initWithDelegate:(id<BRCEventsFilterTableViewControllerDelegate>)delegate
{
    if (self = [self init]) {
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Filter";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:BRCFilterTableViewCellIdentifier];
    
    self.timeStrings = @[@"Show Expired Events", @"Sort Events by Start Time"];
    
    self.showExpiredEvents = [[NSUserDefaults standardUserDefaults] showExpiredEvents];
    self.shouldSortEventsByStartTime = [[NSUserDefaults standardUserDefaults] shouldSortEventsByStartTime];
    
    //All the event types to select from
    NSArray *eventTypes = @[@(BRCEventTypeWorkshop),
                            @(BRCEventTypePerformance),
                            @(BRCEventTypeSupport),
                            @(BRCEventTypeParty),
                            @(BRCEventTypeCeremony),
                            @(BRCEventTypeGame),
                            @(BRCEventTypeFire),
                            @(BRCEventTypeAdult),
                            @(BRCEventTypeKid),
                            @(BRCEventTypeParade),
                            @(BRCEventTypeFood)];
    
    NSMutableArray *eventTypeMutableArray = [NSMutableArray new];
    
    NSArray *storedSelectedEventTypes = [[NSUserDefaults standardUserDefaults] selectedEventTypes];
    
    [eventTypes enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        BRCEventType type = [number unsignedIntegerValue];
        BRCEventTypeContainer *container = [[BRCEventTypeContainer alloc] initWithType:type];
        container.isSelected = [storedSelectedEventTypes containsObject:@(type)];
        
        [eventTypeMutableArray addObject:container];
    }];
    
    self.eventTypeArray = [eventTypeMutableArray copy];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    self.eventTypeArray = [self.eventTypeArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    
    UIBarButtonItem *doneBottun = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    self.navigationItem.rightBarButtonItem = doneBottun;
    
    
    [self.view addSubview:self.tableView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSArray *filteredArray = [self filteredTypes];
    [[NSUserDefaults standardUserDefaults] setSelectedEventTypes:filteredArray];
    [[NSUserDefaults standardUserDefaults] setShowExpiredEvents:self.showExpiredEvents];
    
    BOOL didChangeSort = NO;
    BOOL oldShouldSortEventsByStartTime = [[NSUserDefaults standardUserDefaults] shouldSortEventsByStartTime];
    if (self.shouldSortEventsByStartTime != oldShouldSortEventsByStartTime) {
        didChangeSort = YES;
    }
    [[NSUserDefaults standardUserDefaults] setShouldSortEventsByStartTime:self.shouldSortEventsByStartTime];
    if (didChangeSort) {
        [self.delegate didSetNewSortSettingsInFilterTableViewController:self];
    }
    
    [self.delegate didSetNewFilterSettingsInFilterTableViewController:self];    
}

- (NSArray *)filteredTypes
{
    NSArray *filteredArray = [self.eventTypeArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isSelected = YES"]];
    filteredArray = [filteredArray valueForKey:@"type"];
    return filteredArray;
}

- (void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma - mark UITableViewDataSource Methods

////// Required //////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.timeStrings count];
    }
    else if (section == 1) {
        return [self.eventTypeArray count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BRCFilterTableViewCellIdentifier];
    
    BOOL showCheckMark = NO;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            showCheckMark = self.showExpiredEvents;
        } else if (indexPath.row == 1) {
            showCheckMark = self.shouldSortEventsByStartTime;
        }
        NSString *text = self.timeStrings[indexPath.row];
        cell.textLabel.text = text;
        
    } else if (indexPath.section == 1) {
        BRCEventTypeContainer *container = self.eventTypeArray[indexPath.row];
        showCheckMark = container.isSelected;
        cell.textLabel.text = container.title;
    }
    
    
    if (showCheckMark) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Time";
    }
    else if (section == 1) {
        return @"Type";
    }
    return @"";
}


#pragma - mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            self.showExpiredEvents = !self.showExpiredEvents;
        } else if (indexPath.row == 1) {
            self.shouldSortEventsByStartTime = !self.shouldSortEventsByStartTime;
        }
    }
    else if (indexPath.section == 1) {
        BRCEventTypeContainer *container = self.eventTypeArray[indexPath.row];
        container.isSelected = !container.isSelected;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}



@end

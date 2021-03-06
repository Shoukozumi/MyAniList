//
//  AniListDatePickerView.m
//  AniList
//
//  Created by Corey Roberts on 6/9/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "AniListDatePickerView.h"

@interface AniListDatePickerView()
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIToolbar *toolbar;
@end

@implementation AniListDatePickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        self.datePicker = [[UIDatePicker alloc] init];
        self.datePicker.datePickerMode = UIDatePickerModeDate;
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        
        self.toolbar.items = @[cancelButton, flex, doneButton];
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, [UIScreen mainScreen].bounds.size.width, self.toolbar.frame.size.height + self.datePicker.frame.size.height);
        
        self.toolbar.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.toolbar.frame.size.width, self.toolbar.frame.size.height);
        self.datePicker.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y + self.toolbar.frame.size.height, self.datePicker.frame.size.width, self.datePicker.frame.size.height);
        
        [self addSubview:self.toolbar];
        [self addSubview:self.datePicker];
    }
    return self;
}

- (void)cancelButtonPressed:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(cancelPressed)]) {
        // Send date to delegate.
        [self.delegate cancelPressed];
    }
}

- (void)doneButtonPressed:(id)sender {
    ALLog(@"Done button pressed. Sending date %@.", self.datePicker.date);
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(dateSelected:forType:)]) {
        // Send date to delegate.
        [self.delegate dateSelected:self.datePicker.date forType:self.datePickerType];
    }
}

- (void)setDate:(NSDate *)date {
    if(date) {
        self.datePicker.date = date;
    }
    else {
        self.datePicker.date = [NSDate date];
    }
}

@end

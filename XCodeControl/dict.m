//
//  dict.m
//  XCodeControl
//
//  Created by Ingo Krabbe on 28.05.15.
//  Copyright (c) 2015 Ingo Krabbe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProjectDict : NSMutableDictionary {
}
@end

@implementation ProjectDict
-(id)init
{
	self = [super initWithContentsOfFile:@"XCodeControl.xcodeproj/project.pbxproj"];
}

-(void)dealloc
{
	[self writeToFile:@"output.pbxproj"];
}
@end
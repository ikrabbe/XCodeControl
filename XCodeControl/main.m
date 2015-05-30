//
//  main.m
//  XCodeControl
//
//  Created by Ingo Krabbe on 28.05.15.
//  Copyright (c) 2015 Ingo Krabbe. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void operateProject(int argc, const char** argv);

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		// insert code here...
		operateProject(argc,argv);
	}
	return 0;
}

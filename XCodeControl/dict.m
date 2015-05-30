//
//  dict.m
//  XCodeControl
//
//  Created by Ingo Krabbe on 28.05.15.
//  Copyright (c) 2015 Ingo Krabbe. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct objectID {
	char frontByte[2];
	UInt32 midBytes;
	char tailByte[16];
} objectID;

@interface ProjectDict : NSObject {
@public
	NSMutableDictionary* p;
	NSMutableDictionary* o;
	NSMutableArray* path;
	objectID nextID;
}
-(NSString*)sourceFile:(NSString*)sp;
-(NSString*)buildFile:(NSString*)fileref;
-(NSString*)newObjId;
-(NSDictionary*)root;
-(NSDictionary*)main;
-(NSDictionary*)obj:(NSString*)id;
-(void)del:(NSString*)id;
-(NSArray*)sortedObjectKeys;
-(NSArray*)targets;
-(NSArray*)buildPhasesOf:(NSString*)target;
+(objectID)getIdFrom:(NSString*)key;
+(NSArray*)childrenOf:(NSDictionary*)d;
-(NSString*)path:(NSString*)name ofParent:(NSDictionary*)parent;
-(void)addChild:(NSString*)x to:(NSString*)objid;
-(void)addTo:(NSString*)name of:(NSString*)objid value:(id)v;
@end

void operateProject(int argc, const char** argv)
{
	ProjectDict* project  = [[ProjectDict alloc] init];
	__block BOOL success;
	NSString* x = [project path:@"XCodeControl" ofParent:[project main]];	/* group */
	NSString* y;	/* source file */
	NSString* z;	/* build file */
	y = [project sourceFile:@"test.m"];
	z = [project buildFile:y];
	success = FALSE;
	[[project targets] enumerateObjectsUsingBlock:^(NSString* target, NSUInteger i, BOOL*stop){
		NSArray* phases = [project buildPhasesOf: target];
		[phases enumerateObjectsUsingBlock:^(NSString* phase, NSUInteger j, BOOL*stop2){
			NSString* type = [[project obj:phase] valueForKey:@"isa"];
			if(NSOrderedSame ==[type compare:@"PBXSourcesBuildPhase"]) {
				[project addTo:@"files" of:phase value:z];
				success = TRUE;
			}
		}];
	}];
	if(!success) {
		NSLog(@"not found a single SourceBuildPhase in the project targets!");
		[project del:y];
		[project del:z];
	} else {
		NSLog(@"added build source file \"%@\" in path XCodeControl", @"test.m");
		[project addTo:@"children" of:x value:y];
	}
}

@implementation ProjectDict
-(id)init
{
	if(self = [super init]) {
		NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:
			@"XCodeControl.xcodeproj/project.pbxproj"];
		p = [[NSMutableDictionary alloc] init];
		o = [[NSMutableDictionary alloc] init];
		[p setDictionary:dict];
		[o setDictionary:[p valueForKey:@"objects"]];
		nextID = [ProjectDict getIdFrom:[[self sortedObjectKeys] lastObject]];
		[self newObjId];
	}
	return self;
}

/** randomize next key
		srandom((unsigned)time(0)+(unsigned)nextID.midBytes);
		nextID.midBytes = ((UInt32)random()) & 0x00ffffff;
		while( (origMid > nextID.midBytes) && (origMid - nextID.midBytes < 8129) ) {
			NSLog(@"Mid Byte Collision? %s, %X, %X", d, origMid, nextID.midBytes);
			nextID.midBytes = ((UInt32)random()) & 0x00ffffff;
		}
*/
+(objectID)getIdFrom:(NSString*)key
{
	objectID ret;
	unsigned char d[25], *dp;
	[key getCString:(char*)d maxLength:25 encoding:NSUTF8StringEncoding];
	memcpy(ret.frontByte,d,2);
	memcpy(ret.tailByte,d+8,16);
	ret.midBytes = 0;
	for(dp=&d[2]; dp-d<8; dp+=2) {
		unsigned char hi, lo;
		ret.midBytes<<=8;
		hi = dp[0];
		lo = dp[1];
		if(hi>='A') hi = (hi-'A'+10);
		else hi = (hi - '0');
		if(lo>='A') lo = (lo-'A'+10);
		else lo = (lo - '0');
		ret.midBytes += (hi<<4)+lo;
	}
	return ret;
}

-(NSString*)newObjId
{
	unsigned char d[25], *dp;
	UInt32 m = nextID.midBytes;
	memcpy(d,nextID.frontByte,2);
	memcpy(d+8,nextID.tailByte,16);
	for(dp=&d[2]; dp-d<8; dp+=2) {
		unsigned char hi, lo;
		unsigned char i = dp-d-2;
		hi = m >> (20-i*4) &0xf;
		lo = m >> (16-i*4) &0xf;
		if(hi>=10) hi = 'A'+(hi-10);
		else hi = '0'+hi;
		if(lo>=10) lo = 'A'+(lo-10);
		else lo = '0'+lo;
		dp[0] = hi;
		dp[1] = lo;
	}
	d[24]=0;
	nextID.midBytes = (nextID.midBytes + 0xff000001) & 0x00ffffff;
	return [[NSString alloc] initWithCString:(const char*)d encoding:NSUTF8StringEncoding];
}

- (NSString*)sourceFile:(NSString*)sp
{
	NSDictionary* n = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"PBXFileReference",@"isa",
		sp,@"path",
		@"<group>",@"sourceTree",
		nil
	];
	NSString* oid = [self newObjId];
	[o setValue:n forKey:oid];
	return oid;
}

-(NSString*)buildFile:(NSString*)fileref
{
	NSDictionary* n = [[NSDictionary alloc] initWithObjectsAndKeys:
		fileref, @"fileRef",
		@"PBXBuildFile", @"isa",
		nil
	];
	NSString* oid = [self newObjId];
	[o setValue:n forKey:oid];
	return oid;
}

-(NSDictionary*)root
{
	return [self obj:[
		p valueForKey:@"rootObject"
	]];
}

-(NSArray*)buildPhasesOf:(NSString*)target
{
	return (NSArray*)[[o valueForKey:target] valueForKey:@"buildPhases"];
}

-(NSArray*)targets
{
	return [[self root] valueForKey:@"targets"];
}

-(NSDictionary*)main
{
	return [self obj:[
		[self root] valueForKey:@"mainGroup"
	]];
}

+(NSArray*)childrenOf:(NSDictionary*)d
{
	return [d valueForKey:@"children"];
}

-(NSArray*)sortedObjectKeys
{
	return [[o allKeys] sortedArrayUsingComparator: ^(NSString* a, NSString* b){
		return ([a compare:b]);
	}];
}

-(NSString*)path:(NSString*)name ofParent:(NSDictionary*)parent;
{
	NSEnumerator *idx = [[ProjectDict childrenOf:parent] objectEnumerator];
	NSString* i;
 
	while (i = [idx nextObject]) {
		NSDictionary* O = [self obj:i];
		NSString* t = [O valueForKey:@"isa"];
		if(NSOrderedSame == [t compare:@"PBXGroup"]) {
			NSString* N = [O valueForKey:@"name"];
			if (NSOrderedSame == [N compare:name]) {
				return i;
			}
		}
	}
	return @"";
}

-(void)addTo:(NSString*)name of:(NSString*)objid value:(id)v
{
	NSMutableDictionary* n = [[NSMutableDictionary alloc] init];
	NSMutableArray* C = [[NSMutableArray alloc] init];

	[n setDictionary:[self obj:objid]];
	[C addObjectsFromArray:[n valueForKey:name]];
	[C addObject:v];
	[n removeObjectForKey:name];
	[n setValue:C forKey:name];
	[o removeObjectForKey:objid];
	[o setValue:n forKey:objid];
}

-(void)addChild:(NSString*)x to:(NSString*)objid
{
	[self addTo:@"children" of:objid value:x];
}

- (NSDictionary*)obj:(NSString*)id
{
	return [o valueForKey:id];
}

-(void)del:(NSString*)id
{
	[o removeObjectForKey:id];
}

-(void)save
{
	NSMutableString *projString = [NSMutableString stringWithString:@"// !$*UTF8*$!\n"];
	NSData* projData;
	[p removeObjectForKey:@"objects"];	/* replace new objects */
	[p setValue:o forKey:@"objects"];
	[projString appendString:[p description]];
	projData = [projString dataUsingEncoding:NSUTF8StringEncoding];
	[projData writeToFile:@"pbxproj.out"  atomically:NO];
}

-(void)dealloc
{
	[self save];
}
@end
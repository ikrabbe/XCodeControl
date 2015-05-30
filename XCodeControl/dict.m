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

/* import */
extern void testFunction(void);

/* export */
@class ProjectDict;
extern void operateProject(int argc, const char** argv);
extern BOOL addProjectBuildFile(ProjectDict* proj, const char* arg);

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
	NSString* group;
	NSString* target;
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
-(void)setCurrentGroup:(NSString*)name ofParent:(NSDictionary*)parent;
-(void)setCurrentTarget:(NSString*)name;
-(NSString*)currentGroup;
-(NSString*)currentTarget;
-(NSArray*)targets;
-(NSArray*)buildPhasesOf:(NSString*)target;
+(objectID)getIdFrom:(NSString*)key;
+(NSArray*)childrenOf:(NSDictionary*)d;
-(NSString*)path:(NSString*)name ofParent:(NSDictionary*)parent;
-(void)addChild:(NSString*)x to:(NSString*)objid;
-(void)addTo:(NSString*)name of:(NSString*)objid value:(id)v;
@end

typedef struct Option Option;
typedef BOOL(*OptionFunction)(ProjectDict* project, const char* arg);
struct Option {
	char c;	/* single char Option or 0 */
	char* s;	/* long Option or "" */
	int t;		/* type of argument 0:not-found 1:none, 2:int, 3:string, 4:char, FLAG:8:optional */
	char* desc;	/* verbose description */
	OptionFunction func;
};

enum OptionArgType { optNotFound, optNoArg, optIntArg, optStringArg, optCharArg,
	optArgFlag=8, optEmbeddedArg=16, optLongFlag=32, optAllFlags=8|16|32 };
enum OptionNames {
	optBuildSourceFile,
	optSetGroup,
	optSetTarget,
	optInput,
	optHelp,
	optTargetSourceFile,
	optEndOfOptions
};
static Option progopts[optEndOfOptions+1] = {
	{'b',"buildSourceFile",optStringArg, "add a source file to the current group to be build in all targets", addProjectBuildFile},
	{'p',"setGroup",optStringArg,"set current group", NULL},
	{'t',"setTarget",optStringArg,"set current target", NULL},
	{'i',"input",optStringArg,"read input file", NULL},
	{'h',"help",optStringArg|optArgFlag,"show help for Option", NULL},
	{0,"targetSourceFile",optStringArg,"add a source file to the current target", NULL},
	{0,"",0,"end of options", NULL}
};
static int optionId(Option* opts, const char* arg, Option** O); /* returns Option.t+1 or 0 */
static int shortOperationId(Option* opts, const char* arg, Option** O); /* returns Option.t+1 or 0 */
static int longOperationId(Option* opts, const char* arg, Option** O); /* returns Option.t+1 or 0 */
static BOOL operateOn(ProjectDict* project, const Option* O, const char* arg);

/* implementation */
int optionId(Option* opts, const char* arg, Option** O)
{
	if(arg[0]=='-') {
		if(arg[1]=='-') {
			return longOperationId(opts,arg+2, O);
		} else {
			return shortOperationId(opts,arg+1, O);
		}
	} else {
		return 0;
	}
}

int shortOperationId(Option* opts, const char* arg, Option** O)
{
	Option*op;
	for(op=opts; op->t>0;++op) {
		if(op->c == arg[0]){
			*O = op;
			if(arg[1] != 0) {
				return (op->t|optEmbeddedArg)+1;
			} else {
				return op->t + 1;
			}
		}
	}
	return 0;
}

int longOperationId(Option* opts, const char* arg, Option** O)
{
	Option*op;
	unsigned l;
	for(op=opts; op->t>0;++op) {
		l = (unsigned)strlen(op->s);
		if(0==memcmp(op->s,arg,l)){
			*O = op;
			if(arg[l] == '=') {
				return (op->t|optEmbeddedArg|optLongFlag)+1;
			} else if(arg[l]==0){
				return (op->t|optLongFlag) + 1;
			} else {
				return -((op->t|optLongFlag) +1);	/* failure */
			}
		}
	}
	return 0;
}

void operateProject(int argc, const char** argv)
{
	ProjectDict* project  = [[ProjectDict alloc] init];
	int i;
	int optid = 0, argtype = 0;
	Option* O = NULL;
	const char* arg = "";
	[project setCurrentGroup:@"XCodeControl" ofParent:[project main]];	/* FIXME: change to first main group */
	/* FIXME: set current target to first target */
	for(i=1; i<argc; ++i) {
		if(argtype > 0) {
			arg = argv[i];
			operateOn(project,O,arg);
			arg="";
			O = NULL;
			argtype = 0;
		} else {
			optid = optionId(progopts, argv[i], &O);
			argtype = optid&~optAllFlags;
			if(argtype == 0) {
				NSLog(@"Option failure %d", optid);
				return;
			} else if(optid&optEmbeddedArg) {
				if(optid&optLongFlag) {
					arg = argv[i]+strlen(O->s)+1;
				} else {
					arg = argv[i]+1;
				}
				operateOn(project, O, arg);
				argtype = 0;
				O = NULL;
				argtype = 0;
			}
		}
	}
}

BOOL operateOn(ProjectDict* project, const Option* O, const char* arg)
{
	if(O->func) {
		return O->func(project,arg);
	}
	else {
		NSLog(@"Operation \"%s\" has no function (not implemented)", O->desc);
		return FALSE;
	}
}

BOOL addProjectBuildFile(ProjectDict* project, const char* arg)
{
	NSString* filename = [NSString stringWithCString:arg encoding:NSUTF8StringEncoding];
	__block BOOL success = FALSE;
	NSString* y;	/* source file */
	NSString* z;	/* build file */
	y = [project sourceFile:@"test2.m"];
	z = [project buildFile:y];
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
		NSLog(@"added build source file \"%@\" in path XCodeControl", @"test2.m");
		[project addTo:@"children" of:[project currentGroup] value:y];
	}
	return success;
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

-(void)setCurrentGroup:(NSString*)name ofParent:(NSDictionary*)parent
{
	group = [self path:name ofParent:parent];
}

-(void)setCurrentTarget:(NSString*)name
{
	target = name;
}

-(NSString*)currentGroup
{
	return group;
}
-(NSString*)currentTarget
{
	return target;
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

-(NSArray*)buildPhasesOf:(NSString*)T
{
	return (NSArray*)[[o valueForKey:T] valueForKey:@"buildPhases"];
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
	[projString appendString:"\n"];			/* keep the file sane */
	projData = [projString dataUsingEncoding:NSUTF8StringEncoding];
	[projData writeToFile:@"pbxproj.out"  atomically:NO];
}

-(void)dealloc
{
	[self save];
}
@end
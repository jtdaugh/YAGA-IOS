@interface NameGenerator : NSObject
{
  NSMutableArray *vowel;
	
	NSMutableArray *malePre;
	NSMutableArray *maleStart;
	NSMutableArray *maleMiddle;
	NSMutableArray *maleEnd;
	NSMutableArray *malePost;
	
	NSMutableArray *male;
	
	NSMutableArray *femalePre;
	NSMutableArray *femaleStart;
	NSMutableArray *femaleMiddle;
	NSMutableArray *femaleEnd;
	NSMutableArray *femalePost;
	
	NSMutableArray *female;
    
    NSMutableDictionary *generatedNames;
}

+ (instancetype)sharedGeneratror;

- (NSString *)getName;

- (NSString *)getName:(BOOL)generated male:(BOOL)sex prefix:(BOOL)prefix postfix:(BOOL)postfix;

- (NSString*)nameForPhoneNumber:(NSString*)phoneNumber;
@end

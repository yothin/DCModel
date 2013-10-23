# DCModel #

DCModel is an abstraction of core data APIs. It borrows from active record syntax to make core data interaction fun and easy. It also has network methods that automatically parses JSON data into core data objects. If that was not enough, it also adds primary key validation to your objects to avoid duplicates. I know, your brain just exploded. To the examples!

# Examples #
First we create a subclass of NSManagedObject as usual, but we also import DCModel.

	#import "DCModel.h"

	@interface TweetModel : NSManagedObject

	//these both match the values in coreData xcdatamodeld file and the json value name
	@property(nonatomic,strong)NSString* text; 
	@property(nonatomic,strong)NSString* id_str;

	@end

Boom! That is it. Now the magic begins.

	[TweetModel getAll:@"https://api.twitter.com/1/statuses/user_timeline.json?include_entities=true&include_rts=true&screen_name=twitterapi&count=2" finished:^(id items){
	    [TweetModel saveObjects:items]; //objects are now saved to coreData.
	    [TweetModel all:^(id items){ //pulls all the items from coreData asynchronously 
	        for(TweetModel* item in items)
	            NSLog(@"coreData item text: %@ id_str: %@",item.text,item.id_str);
	    }];
	}];

With just 5 lines of code, we converted JSON data to coreData objects, saved them, and pulled them from coreData completely asynchronously.
	
# Primary Key Validation #

Ok, so now I am sure you want to know about the Primary key validation I mentioned. Well here it is:
	
	//add this to your implemention file of your NSManagedObject subclass (TwitterModel.m in our example)
	//return the property name of the key you want to be primary.
	+(NSString*)primaryKey
	{
	    return @"id_str";
	}
Done. Now anytime you save an object, it will validate to ensure that the object does not exist before adding it in. 

# Requirements/Dependencies  #

The CoreData frame work is required.

# Install #

The recommended approach for installing DCModel is via the CocoaPods package manager, as it provides flexible dependency management and dead simple installation.

via CocoaPods

Install CocoaPods if not already available:

	$ [sudo] gem install cocoapods
	$ pod setup
Change to the directory of your Xcode project, and Create and Edit your Podfile and add DCModel:

	$ cd /path/to/MyProject
	$ touch Podfile
	$ edit Podfile
	platform :ios, '5.0' 
	# Or platform :osx, '10.7'
	pod 'DCModel'

Install into your project:

	$ pod install
	
Open your project in Xcode from the .xcworkspace file (not the usual project file)

# License #

DCModel is license under the Apache License.

# Contact #

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam